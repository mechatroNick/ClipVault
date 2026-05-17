//
//  ClipboardRepositoryTests.swift
//  ClipVaultTests
//
//  Created by ClipVault.
//

import XCTest
@testable import ClipVault
import GRDB
import CryptoKit

final class ClipboardRepositoryTests: XCTestCase {
    
    private var repository: ClipboardRepository!
    private var dbManager: DatabaseManager!
    private var keychainManager: KeychainManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Use in-memory DB for tests
        dbManager = try DatabaseManager(path: ":memory:")
        
        let serviceName = "com.clipvault.test.repo.\(UUID().uuidString)"
        keychainManager = KeychainManager(service: serviceName)
        
        repository = ClipboardRepository(
            dbManager: dbManager,
            encryptionService: EncryptionService(),
            keychainManager: keychainManager
        )
    }
    
    override func tearDownWithError() throws {
        try? keychainManager.deleteKey()
        repository = nil
        keychainManager = nil
        dbManager = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Integration: Store -> Encrypt -> Decrypt -> Retrieve -> Verify
    
    func testSaveAndFetch_RoundTrip() throws {
        // Arrange
        let plainText = Data("secret plain text".utf8)
        let richText = Data("{\\rtf1 secret rtf}".utf8)
        let metadata = Data("{\"app\":\"test\"}".utf8)
        
        var entry = ClipboardEntry(
            timestamp: Date(),
            contentType: "text",
            plainTextContent: plainText,
            richTextContent: richText,
            metadata: metadata
        )
        
        // Act
        try repository.save(&entry)
        let savedId = try XCTUnwrap(entry.id)
        
        // Retrieve via repository (should decrypt)
        let fetched = try repository.fetch(id: savedId)
        
        // Assert
        XCTAssertEqual(fetched.plainTextContent, plainText)
        XCTAssertEqual(fetched.richTextContent, richText)
        XCTAssertEqual(fetched.metadata, metadata)
        
        // Verify plainTextSearchContent was extracted correctly
        XCTAssertEqual(fetched.plainTextSearchContent, "secret plain text")
    }
    
    // MARK: - Verify Encryption at Rest
    
    func testSave_EncryptsDataInDatabase() throws {
        // Arrange
        let plainText = Data("highly confidential data".utf8)
        var entry = ClipboardEntry(
            timestamp: Date(),
            contentType: "text",
            plainTextContent: plainText
        )
        
        // Act
        try repository.save(&entry)
        let savedId = try XCTUnwrap(entry.id)
        
        // Assert by reading directly from DB without repository
        try dbManager.dbQueue.read { db in
            let rawEntry = try XCTUnwrap(ClipboardEntry.fetchOne(db, key: savedId))
            let rawData = try XCTUnwrap(rawEntry.plainTextContent)
            
            // Raw data should not be equal to plain text
            XCTAssertNotEqual(rawData, plainText)
            
            // Raw data should not contain plain text substring
            let rawString = String(data: rawData, encoding: .utf8) ?? ""
            XCTAssertFalse(rawString.contains("confidential"))
        }
    }
    
    // MARK: - Search
    
    func testSearch_FindsMatchingEntries() throws {
        // Arrange
        var entry1 = ClipboardEntry(timestamp: Date(), contentType: "text", plainTextContent: Data("apple banana cherry".utf8))
        var entry2 = ClipboardEntry(timestamp: Date(), contentType: "text", plainTextContent: Data("date elderberry fig".utf8))
        
        try repository.save(&entry1)
        try repository.save(&entry2)
        
        // Act
        let results = try repository.search("banana")
        
        // Assert
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.id, entry1.id)
        XCTAssertEqual(String(data: results.first!.plainTextContent!, encoding: .utf8), "apple banana cherry")
    }
    
    // MARK: - Fetch All
    
    func testFetchAll_ReturnsAllEntriesOrderedByTimestamp() throws {
        // Arrange
        var entry1 = ClipboardEntry(timestamp: Date(timeIntervalSince1970: 100), contentType: "text")
        var entry2 = ClipboardEntry(timestamp: Date(timeIntervalSince1970: 200), contentType: "text") // Newer
        
        try repository.save(&entry1)
        try repository.save(&entry2)
        
        // Act
        let results = try repository.fetchAll()
        
        // Assert
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].id, entry2.id, "Newer entry should be first")
        XCTAssertEqual(results[1].id, entry1.id)
    }
    
    // MARK: - Delete
    
    func testDelete_RemovesEntry() throws {
        // Arrange
        var entry = ClipboardEntry(timestamp: Date(), contentType: "text")
        try repository.save(&entry)
        let id = try XCTUnwrap(entry.id)
        
        // Act
        try repository.delete(id: id)
        
        // Assert
        XCTAssertThrowsError(try repository.fetch(id: id)) { error in
            XCTAssertEqual(error as? ClipboardRepositoryError, .entryNotFound)
        }
    }
    
    func testDelete_NonExistentEntry_ThrowsError() throws {
        XCTAssertThrowsError(try repository.delete(id: 999)) { error in
            XCTAssertEqual(error as? ClipboardRepositoryError, .entryNotFound)
        }
    }
    
    // MARK: - Pin / Unpin
    
    func testPinAndUnpin_UpdatesStatus() throws {
        // Arrange
        var entry = ClipboardEntry(timestamp: Date(), contentType: "text")
        try repository.save(&entry)
        let id = try XCTUnwrap(entry.id)
        
        // Act & Assert
        try repository.pin(id: id)
        var fetched = try repository.fetch(id: id)
        XCTAssertTrue(fetched.isPinned)
        
        try repository.unpin(id: id)
        fetched = try repository.fetch(id: id)
        XCTAssertFalse(fetched.isPinned)
    }
    
    func testPin_NonExistentEntry_ThrowsError() throws {
        XCTAssertThrowsError(try repository.pin(id: 999)) { error in
            XCTAssertEqual(error as? ClipboardRepositoryError, .entryNotFound)
        }
    }
    
    // MARK: - Purge
    
    func testPurgeExpired_RemovesOldUnpinnedEntries() throws {
        // Arrange
        let now = Date()
        let oldDate = now.addingTimeInterval(-1000)
        let newDate = now.addingTimeInterval(-100)
        
        var oldUnpinned = ClipboardEntry(timestamp: oldDate, contentType: "text")
        var oldPinned = ClipboardEntry(timestamp: oldDate, contentType: "text", isPinned: true)
        var newUnpinned = ClipboardEntry(timestamp: newDate, contentType: "text")
        
        try repository.save(&oldUnpinned)
        try repository.save(&oldPinned)
        try repository.save(&newUnpinned)
        
        // Act - Purge entries older than 500 seconds
        try repository.purgeExpired(olderThan: 500)
        
        // Assert
        let results = try repository.fetchAll()
        let resultIds = results.compactMap { $0.id }
        
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(resultIds.contains(oldPinned.id!))
        XCTAssertTrue(resultIds.contains(newUnpinned.id!))
        XCTAssertFalse(resultIds.contains(oldUnpinned.id!))
    }
}
