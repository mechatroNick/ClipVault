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
    let dbManager: DatabaseManager
    private let encryptionService: EncryptionService
    private let keychainManager: KeychainManager
    private let contentFilter: SensitiveContentFilter
    private let vaultManager: VaultManager
    private let settings: SettingsManager
    
    init(dbManager: DatabaseManager = .shared,
         encryptionService: EncryptionService = EncryptionService(),
         keychainManager: KeychainManager = KeychainManager(service: "com.clipvault.encryption"),
         contentFilter: SensitiveContentFilter = SensitiveContentFilter(),
         vaultManager: VaultManager = .shared,
         settings: SettingsManager = .shared) {
        self.dbManager = dbManager
        self.encryptionService = encryptionService
        self.keychainManager = keychainManager
        self.contentFilter = contentFilter
        self.vaultManager = vaultManager
        self.settings = settings
    }
    
    func getEncryptionKey() throws -> SymmetricKey {
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
        
        let thresholdBytes = settings.largeFileThresholdMB * 1024 * 1024
        
        // Handle Large File Vaulting automatically
        func processLargeData(_ data: Data?, extension ext: String) throws -> (Data?, String?, Bool) {
            guard let data = data else { return (nil, nil, false) }
            if data.count > thresholdBytes {
                let path = try vaultManager.saveToVault(data: data, extension: ext, using: key)
                return (nil, path, true)
            }
            return (data, nil, false)
        }
        
        // Extract FTS preview before encryption or vaulting
        if let ptData = entry.plainTextContent,
           let ptString = String(data: ptData, encoding: .utf8) {
            let preview = String(ptString.prefix(200))
            entry.plainTextSearchContent = contentFilter.redact(preview)
        }
        
        if entry.contentType == "image", let data = entry.imageData {
            let (_, path, vaulted) = try processLargeData(data, extension: "tiff")
            if vaulted {
                entry.imageData = nil
                entry.fileURL = path
                entry.isVaultStored = true
            }
        } else if (entry.contentType == "rtf" || entry.contentType == "html"), let data = entry.richTextContent {
            let (_, path, vaulted) = try processLargeData(data, extension: entry.contentType)
            if vaulted {
                entry.richTextContent = nil
                entry.fileURL = path
                entry.isVaultStored = true
            }
        } else if let data = entry.plainTextContent {
            let (_, path, vaulted) = try processLargeData(data, extension: "txt")
            if vaulted {
                entry.plainTextContent = nil
                entry.fileURL = path
                entry.isVaultStored = true
            }
        }

        func encryptData(_ data: Data?) throws -> Data? {
            guard let data = data else { return nil }
            return try encryptionService.encrypt(plaintext: data, using: key).combined
        }
        
        entry.plainTextContent = try encryptData(entry.plainTextContent)
        entry.richTextContent = try encryptData(entry.richTextContent)
        entry.imageData = try encryptData(entry.imageData)
        entry.metadata = try encryptData(entry.metadata)
        
        try dbManager.insert(&entry)
    }
    
    // MARK: - Decryption Helper
    
    /// Decrypts all sensitive fields of an entry.
    /// Used for on-demand decryption when an item is selected or pasted.
    func decryptContent(for entry: ClipboardEntry) throws -> ClipboardEntry {
        let key = try getEncryptionKey()
        var decryptedEntry = entry
        
        func decryptData(_ data: Data?) throws -> Data? {
            guard let data = data else { return nil }
            let package = try EncryptedPackage(combined: data)
            return try encryptionService.decrypt(package: package, using: key)
        }
        
        if entry.isVaultStored, let path = entry.fileURL {
            let data = try VaultManager.shared.loadFromVault(at: path, using: key)
            switch entry.contentType {
            case "image": decryptedEntry.imageData = data
            case "rtf", "html": decryptedEntry.richTextContent = data
            default: decryptedEntry.plainTextContent = data
            }
        } else {
            decryptedEntry.plainTextContent = try decryptData(entry.plainTextContent)
            decryptedEntry.richTextContent = try decryptData(entry.richTextContent)
            decryptedEntry.imageData = try decryptData(entry.imageData)
        }
        
        decryptedEntry.metadata = try decryptData(entry.metadata)
        
        return decryptedEntry
    }
    
    // MARK: - Observation
    
    /// Returns an AsyncStream of raw entries, updating whenever the database changes.
    /// Metadata visible in the UI (timestamp, type, app, window title, device) is plaintext.
    func observeEntries(limit: Int = 50) -> AsyncStream<[ClipboardEntry]> {
        AsyncStream { continuation in
            let observation = ValueObservation.tracking { db in
                try ClipboardEntry
                    .order(ClipboardEntry.Columns.timestamp.desc)
                    .limit(limit)
                    .fetchAll(db)
            }
            
            let cancellable = observation.start(
                in: dbManager.dbQueue,
                onError: { _ in continuation.finish() },
                onChange: { entries in
                    continuation.yield(entries)
                }
            )
            
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }
    
    // MARK: - Fetching
    
    func fetchAll() throws -> [ClipboardEntry] {
        return try dbManager.fetchAll()
    }
    
    func fetch(id: Int64) throws -> ClipboardEntry {
        let entry = try dbManager.dbQueue.read { db in
            try ClipboardEntry.fetchOne(db, key: id)
        }
        guard let entry = entry else {
            throw ClipboardRepositoryError.entryNotFound
        }
        return entry
    }
    
    func search(_ query: String) throws -> [ClipboardEntry] {
        return try dbManager.search(query)
    }
    
    func fetchLastEntry() throws -> ClipboardEntry? {
        try dbManager.dbQueue.read { db in
            try ClipboardEntry
                .order(ClipboardEntry.Columns.timestamp.desc)
                .fetchOne(db)
        }
    }
    
    // MARK: - Entry Management
    
    func delete(id: Int64) throws {
        _ = try dbManager.dbQueue.write { db in
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
        _ = try dbManager.dbQueue.write { db in
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
        _ = try dbManager.dbQueue.write { db in
            try ClipboardEntry
                .filter(ClipboardEntry.Columns.isPinned == false)
                .filter(ClipboardEntry.Columns.timestamp < cutoffDate)
                .deleteAll(db)
        }
    }
}
