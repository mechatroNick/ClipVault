//
//  ClipboardRepository.swift
//  ClipVault
//
//  Created by ClipVault.
//

import Foundation
import CryptoKit
import GRDB

enum ClipboardRepositoryError: LocalizedError {
    case entryNotFound
    
    var errorDescription: String? {
        switch self {
        case .entryNotFound: return "Clipboard entry not found in the database."
        }
    }
}

/// Orchestrates saving, fetching, and searching clipboard entries,
/// automatically handling AES-GCM encryption/decryption of sensitive fields.
final class ClipboardRepository {
    private let dbManager: DatabaseManager
    private let encryptionService: EncryptionService
    private let keychainManager: KeychainManager
    private let contentFilter: SensitiveContentFilter
    
    init(dbManager: DatabaseManager = .shared,
         encryptionService: EncryptionService = EncryptionService(),
         keychainManager: KeychainManager = KeychainManager(service: "com.clipvault.encryption"),
         contentFilter: SensitiveContentFilter = SensitiveContentFilter()) {
        self.dbManager = dbManager
        self.encryptionService = encryptionService
        self.keychainManager = keychainManager
        self.contentFilter = contentFilter
    }
    
    private func getEncryptionKey() throws -> SymmetricKey {
        if let key = try keychainManager.retrieveKey() {
            return key
        }
        return try keychainManager.generateAndStoreKey()
    }
    
    // MARK: - Save
    
    /// Encrypts sensitive fields and saves the entry to the database.
    ///
    /// The `plainTextSearchContent` field is populated from `plainTextContent`
    /// before encryption to allow full-text search.
    func save(_ entry: inout ClipboardEntry) throws {
        let key = try getEncryptionKey()
        
        func encryptData(_ data: Data?) throws -> Data? {
            guard let data = data else { return nil }
            return try encryptionService.encrypt(plaintext: data, using: key).combined
        }
        
        // Extract FTS preview before encryption
        if let ptData = entry.plainTextContent,
           let ptString = String(data: ptData, encoding: .utf8) {
            let preview = String(ptString.prefix(200))
            entry.plainTextSearchContent = contentFilter.redact(preview)
        }
        
        entry.plainTextContent = try encryptData(entry.plainTextContent)
        entry.richTextContent = try encryptData(entry.richTextContent)
        entry.imageData = try encryptData(entry.imageData)
        entry.metadata = try encryptData(entry.metadata)
        
        try dbManager.insert(&entry)
    }
    
    // MARK: - Decryption Helper
    
    private func decryptEntry(_ entry: ClipboardEntry, using key: SymmetricKey) throws -> ClipboardEntry {
        var decryptedEntry = entry
        
        func decryptData(_ data: Data?) throws -> Data? {
            guard let data = data else { return nil }
            let package = try EncryptedPackage(combined: data)
            return try encryptionService.decrypt(package: package, using: key)
        }
        
        decryptedEntry.plainTextContent = try decryptData(entry.plainTextContent)
        decryptedEntry.richTextContent = try decryptData(entry.richTextContent)
        decryptedEntry.imageData = try decryptData(entry.imageData)
        decryptedEntry.metadata = try decryptData(entry.metadata)
        
        return decryptedEntry
    }
    
    // MARK: - Fetching
    
    func fetchAll() throws -> [ClipboardEntry] {
        let entries = try dbManager.fetchAll()
        let key = try getEncryptionKey()
        return try entries.map { try decryptEntry($0, using: key) }
    }
    
    func fetch(id: Int64) throws -> ClipboardEntry {
        let entry = try dbManager.dbQueue.read { db in
            try ClipboardEntry.fetchOne(db, key: id)
        }
        guard let entry = entry else {
            throw ClipboardRepositoryError.entryNotFound
        }
        let key = try getEncryptionKey()
        return try decryptEntry(entry, using: key)
    }
    
    func search(_ query: String) throws -> [ClipboardEntry] {
        let entries = try dbManager.search(query)
        let key = try getEncryptionKey()
        return try entries.map { try decryptEntry($0, using: key) }
    }
    
    // MARK: - Entry Management
    
    func delete(id: Int64) throws {
        try dbManager.dbQueue.write { db in
            let deleted = try ClipboardEntry.deleteOne(db, key: id)
            if !deleted {
                throw ClipboardRepositoryError.entryNotFound
            }
        }
    }
    
    func pin(id: Int64) throws {
        try updatePinStatus(id: id, isPinned: true)
    }
    
    func unpin(id: Int64) throws {
        try updatePinStatus(id: id, isPinned: false)
    }
    
    private func updatePinStatus(id: Int64, isPinned: Bool) throws {
        try dbManager.dbQueue.write { db in
            guard var entry = try ClipboardEntry.fetchOne(db, key: id) else {
                throw ClipboardRepositoryError.entryNotFound
            }
            entry.isPinned = isPinned
            try entry.update(db, columns: [ClipboardEntry.Columns.isPinned])
        }
    }
    
    /// Purges entries older than `retentionSeconds` that are not pinned.
    func purgeExpired(olderThan retentionSeconds: TimeInterval) throws {
        let cutoffDate = Date().addingTimeInterval(-retentionSeconds)
        try dbManager.dbQueue.write { db in
            try ClipboardEntry
                .filter(ClipboardEntry.Columns.isPinned == false)
                .filter(ClipboardEntry.Columns.timestamp < cutoffDate)
                .deleteAll(db)
        }
    }
}
