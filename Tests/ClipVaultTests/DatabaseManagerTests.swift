//
//  DatabaseManagerTests.swift
//  ClipVaultTests
//
//  Created by ClipVault.
//

import XCTest
@testable import ClipVault
import GRDB

/// Verifies CRUD operations, FTS5 search, DatabaseManager lifecycle, and edge cases
/// for the ClipVault database layer.
final class DatabaseManagerTests: XCTestCase {

    private var dbManager: DatabaseManager!

    override func setUpWithError() throws {
        try super.setUpWithError()
        dbManager = try DatabaseManager(path: ":memory:")
    }

    override func tearDownWithError() throws {
        dbManager = nil
        try super.tearDownWithError()
    }

    // MARK: - Helpers

    /// Inserts a basic text entry and returns it with the populated id.
    private func insertTextEntry(text: String, plainTextSearchContent: String? = nil) throws -> ClipboardEntry {
        var entry = ClipboardEntry(
            timestamp: Date(),
            contentType: .text,
            plainTextContent: text.data(using: .utf8),
            richTextContent: nil,
            imageData: nil,
            plainTextSearchContent: plainTextSearchContent ?? text,
            fileURL: nil,
            sourceApplication: nil,
            metadata: nil
        )
        try dbManager.dbQueue.write { db in
            try entry.insert(db)
        }
        return entry
    }

    // MARK: - CRUD Operations

    func testInsertEntry() throws {
        var entry = ClipboardEntry(
            timestamp: Date(),
            contentType: .text,
            plainTextContent: "Hello".data(using: .utf8),
            richTextContent: nil,
            imageData: nil,
            fileURL: nil,
            sourceApplication: nil,
            metadata: nil
        )
        try dbManager.dbQueue.write { db in
            try entry.insert(db)
        }

        XCTAssertNotNil(entry.id, "Entry id should be populated after insert")

        let id = try XCTUnwrap(entry.id)
        let fetched = try dbManager.dbQueue.read { db in
            try ClipboardEntry.filter(Column("id") == id).fetchOne(db)
        }
        let unwrapped = try XCTUnwrap(fetched, "Entry should be fetchable after insert")
        XCTAssertEqual(unwrapped.id, entry.id)
        XCTAssertEqual(unwrapped.contentType, .text)
    }

    func testInsertEntryViaConvenienceMethod() throws {
        var entry = ClipboardEntry(
            timestamp: Date(),
            contentType: .text,
            plainTextContent: "Convenience".data(using: .utf8),
            richTextContent: nil,
            imageData: nil,
            plainTextSearchContent: "Convenience",
            fileURL: nil,
            sourceApplication: nil,
            metadata: nil
        )
        try dbManager.insert(&entry)

        XCTAssertNotNil(entry.id, "Entry id should be populated after convenience insert")

        let id = try XCTUnwrap(entry.id)
        let fetched = try dbManager.dbQueue.read { db in
            try ClipboardEntry.filter(Column("id") == id).fetchOne(db)
        }
        let unwrapped = try XCTUnwrap(fetched, "Entry should be fetchable after convenience insert")
        XCTAssertEqual(unwrapped.id, entry.id)
        XCTAssertEqual(unwrapped.contentType, .text)
    }

    func testFetchAllEntries() throws {
        try insertTextEntry(text: "Entry 1")
        try insertTextEntry(text: "Entry 2")
        try insertTextEntry(text: "Entry 3")

        let all = try dbManager.dbQueue.read { db in
            try ClipboardEntry.fetchAll(db)
        }
        XCTAssertEqual(all.count, 3, "Should fetch all 3 inserted entries")
    }

    func testFetchAllViaConvenienceMethod() throws {
        // Insert entries with staggered timestamps so we can verify DESC order.
        let t1 = Date(timeIntervalSinceNow: -300)
        let t2 = Date(timeIntervalSinceNow: -200)
        let t3 = Date(timeIntervalSinceNow: -100)

        var e1 = ClipboardEntry(
            timestamp: t1, contentType: .text,
            plainTextContent: "A".data(using: .utf8),
            richTextContent: nil, imageData: nil,
            plainTextSearchContent: "A",
            fileURL: nil,
            sourceApplication: nil, metadata: nil
        )
        var e2 = ClipboardEntry(
            timestamp: t2, contentType: .text,
            plainTextContent: "B".data(using: .utf8),
            richTextContent: nil, imageData: nil,
            plainTextSearchContent: "B",
            fileURL: nil,
            sourceApplication: nil, metadata: nil
        )
        var e3 = ClipboardEntry(
            timestamp: t3, contentType: .text,
            plainTextContent: "C".data(using: .utf8),
            richTextContent: nil, imageData: nil,
            plainTextSearchContent: "C",
            fileURL: nil,
            sourceApplication: nil, metadata: nil
        )
        try dbManager.insert(&e1)
        try dbManager.insert(&e2)
        try dbManager.insert(&e3)

        let entries = try dbManager.fetchAll()
        XCTAssertEqual(entries.count, 3, "Should fetch all 3 entries via convenience method")

        // Verify DESC order: most recent (t3) first.
        XCTAssertEqual(entries[0].id, e3.id)
        XCTAssertEqual(entries[1].id, e2.id)
        XCTAssertEqual(entries[2].id, e1.id)
    }

    func testFetchEntryById() throws {
        let inserted = try insertTextEntry(text: "Lookup Me")

        let fetched = try dbManager.dbQueue.read { db in
            try ClipboardEntry.filter(Column("id") == inserted.id).fetchOne(db)
        }
        let unwrapped = try XCTUnwrap(fetched)
        let content = try XCTUnwrap(unwrapped.plainTextContent)
        XCTAssertEqual(String(data: content, encoding: .utf8), "Lookup Me")
    }

    func testUpdateEntry() throws {
        var entry = try insertTextEntry(text: "Before Update")

        // Update the contentType
        try dbManager.dbQueue.write { db in
            try db.execute(
                sql: "UPDATE clipboardEntry SET contentType = ? WHERE id = ?",
                arguments: [ClipboardContentType.image.rawValue, entry.id]
            )
        }

        let fetched = try dbManager.dbQueue.read { db in
            try ClipboardEntry.filter(Column("id") == entry.id).fetchOne(db)
        }
        let unwrapped = try XCTUnwrap(fetched)
        XCTAssertEqual(unwrapped.contentType, .image, "contentType should reflect the update")
    }

    func testDeleteEntry() throws {
        let inserted = try insertTextEntry(text: "To Delete")

        let id = try XCTUnwrap(inserted.id)
        try dbManager.dbQueue.write { db in
            try db.execute(sql: "DELETE FROM clipboardEntry WHERE id = ?", arguments: [id])
        }

        let fetched = try dbManager.dbQueue.read { db in
            try ClipboardEntry.filter(Column("id") == id).fetchOne(db)
        }
        XCTAssertNil(fetched, "Entry should be nil after deletion")
    }

    func testDeleteAllEntries() throws {
        try insertTextEntry(text: "One")
        try insertTextEntry(text: "Two")
        try insertTextEntry(text: "Three")

        try dbManager.dbQueue.write { db in
            try db.execute(sql: "DELETE FROM clipboardEntry")
        }

        let count = try dbManager.dbQueue.read { db in
            try ClipboardEntry.fetchCount(db)
        }
        XCTAssertEqual(count, 0, "All entries should be deleted")
    }

    // MARK: - Optional Fields

    func testInsertEntryWithAllOptionalsNil() throws {
        var entry = ClipboardEntry(
            timestamp: Date(),
            contentType: .file,
            plainTextContent: nil,
            richTextContent: nil,
            imageData: nil,
            plainTextSearchContent: nil,
            fileURL: nil,
            sourceApplication: nil,
            metadata: nil
        )
        try dbManager.dbQueue.write { db in
            try entry.insert(db)
        }

        let fetched = try dbManager.dbQueue.read { db in
            try ClipboardEntry.filter(Column("id") == entry.id).fetchOne(db)
        }
        let unwrapped = try XCTUnwrap(fetched)
        XCTAssertEqual(unwrapped.contentType, .file)
        XCTAssertNil(unwrapped.plainTextContent)
        XCTAssertNil(unwrapped.richTextContent)
        XCTAssertNil(unwrapped.imageData)
        XCTAssertNil(unwrapped.fileURL)
        XCTAssertNil(unwrapped.sourceApplication)
        XCTAssertNil(unwrapped.metadata)
        XCTAssertNil(unwrapped.plainTextSearchContent)
    }

    func testInsertEntryWithAllFieldsPopulated() throws {
        let now = Date()
        let plainData = "Plain text".data(using: .utf8)
        let richData = "<b>Rich</b>".data(using: .utf8)
        let imageBytes = Data(repeating: 0xAB, count: 256)
        let searchContent = "Searchable plaintext"
        let filePath = "/tmp/test.png"
        let sourceApp = "com.apple.Safari"
        let metaJSON = "{\"key\":\"value\"}".data(using: .utf8)

        var entry = ClipboardEntry(
            timestamp: now,
            contentType: .html,
            plainTextContent: plainData,
            richTextContent: richData,
            imageData: imageBytes,
            plainTextSearchContent: searchContent,
            fileURL: filePath,
            sourceApplication: sourceApp,
            metadata: metaJSON
        )
        try dbManager.dbQueue.write { db in
            try entry.insert(db)
        }

        let fetched = try dbManager.dbQueue.read { db in
            try ClipboardEntry.filter(Column("id") == entry.id).fetchOne(db)
        }
        let unwrapped = try XCTUnwrap(fetched)

        XCTAssertEqual(unwrapped.contentType, .html)
        XCTAssertEqual(unwrapped.plainTextContent, plainData)
        XCTAssertEqual(unwrapped.richTextContent, richData)
        XCTAssertEqual(unwrapped.imageData, imageBytes)
        XCTAssertEqual(unwrapped.fileURL, filePath)
        XCTAssertEqual(unwrapped.sourceApplication, sourceApp)
        XCTAssertEqual(unwrapped.metadata, metaJSON)
        XCTAssertEqual(unwrapped.plainTextSearchContent, searchContent)
        // timestamp precision: SQLite stores milliseconds, Date has nanoseconds.
        // Verify the difference is within 1 second tolerance.
        XCTAssertEqual(unwrapped.timestamp.timeIntervalSince1970,
                       now.timeIntervalSince1970,
                       accuracy: 1.0)
    }

    func testPlainTextSearchContentRoundtrip() throws {
        let searchText = "Decrypted searchable plaintext"
        var entry = ClipboardEntry(
            timestamp: Date(),
            contentType: .text,
            plainTextContent: "EncryptedBlob".data(using: .utf8),
            richTextContent: nil,
            imageData: nil,
            plainTextSearchContent: searchText,
            fileURL: nil,
            sourceApplication: nil,
            metadata: nil
        )
        try dbManager.insert(&entry)

        let fetched = try dbManager.dbQueue.read { db in
            try ClipboardEntry.filter(Column("id") == entry.id).fetchOne(db)
        }
        let unwrapped = try XCTUnwrap(fetched)
        XCTAssertEqual(unwrapped.plainTextSearchContent, searchText,
                       "plainTextSearchContent should roundtrip accurately")
    }

    func testPlainTextSearchContentNilRoundtrip() throws {
        var entry = ClipboardEntry(
            timestamp: Date(),
            contentType: .text,
            plainTextContent: "EncryptedBlob".data(using: .utf8),
            richTextContent: nil,
            imageData: nil,
            plainTextSearchContent: nil,
            fileURL: nil,
            sourceApplication: nil,
            metadata: nil
        )
        try dbManager.insert(&entry)

        let fetched = try dbManager.dbQueue.read { db in
            try ClipboardEntry.filter(Column("id") == entry.id).fetchOne(db)
        }
        let unwrapped = try XCTUnwrap(fetched)
        XCTAssertNil(unwrapped.plainTextSearchContent,
                     "plainTextSearchContent should be nil when inserted as nil")
    }

    // MARK: - FTS5 Search

    func testFTSSearchFindsMatchingEntry() throws {
        try insertTextEntry(text: "Hello World")

        let results = try dbManager.search("World")
        XCTAssertEqual(results.count, 1, "FTS5 should find the entry matching 'World'")

        let content = try XCTUnwrap(results.first?.plainTextContent)
        XCTAssertEqual(String(data: content, encoding: .utf8), "Hello World")
    }

    func testFTSSearchDoesNotFindNonMatchingEntry() throws {
        try insertTextEntry(text: "Hello World")

        let results = try dbManager.search("NonExistentxyz")
        XCTAssertEqual(results.count, 0, "FTS5 should find no results for non-matching text")
    }

    func testFTSSearchIsCaseInsensitive() throws {
        try insertTextEntry(text: "Hello World")

        // Search with lowercase — FTS5 is case-insensitive by default
        let results = try dbManager.search("hello")
        XCTAssertEqual(results.count, 1, "FTS5 search should be case-insensitive")
    }

    func testSearchWithEmptyQueryReturnsEmpty() throws {
        try insertTextEntry(text: "Hello World")

        let results = try dbManager.search("")
        XCTAssertEqual(results.count, 0, "Empty query should return an empty array gracefully")
    }

    func testSearchWithMultipleWords() throws {
        try insertTextEntry(text: "Hello Beautiful World",
                            plainTextSearchContent: "Hello Beautiful World")

        let results = try dbManager.search("Hello World")
        XCTAssertEqual(results.count, 1, "FTS5 should match entry with 'Hello World' against 'Hello Beautiful World'")
    }

    // MARK: - DatabaseManager Lifecycle

    func testSharedInstanceExists() {
        // The shared instance is lazily initialized on first access.
        // If it fails, fatalError terminates the process — acceptable test behavior.
        XCTAssertNotNil(DatabaseManager.shared, "Shared instance should be accessible")
    }

    func testCustomPathInitializer() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let tempPath = tempDir.appendingPathComponent("test_clipvault_custom.db").path
        var customManager: DatabaseManager? = try DatabaseManager(path: tempPath)

        let exists = try customManager!.dbQueue.read { db in
            try db.tableExists("clipboardEntry")
        }
        XCTAssertTrue(exists, "Table should exist in custom-path database")

        // Cleanup temporary database files
        customManager = nil  // Release database handle before file deletion
        try? FileManager.default.removeItem(atPath: tempPath)
        try? FileManager.default.removeItem(atPath: tempPath + "-wal")
        try? FileManager.default.removeItem(atPath: tempPath + "-shm")
    }

    func testMemoryPathInitializer() throws {
        // Already tested implicitly by setUp, but explicit verification.
        let memManager = try DatabaseManager(path: ":memory:")
        let exists = try memManager.dbQueue.read { db in
            try db.tableExists("clipboardEntry")
        }
        XCTAssertTrue(exists, "In-memory database should have schema set up")
    }

    func testWALModeEnabled() throws {
        // In-memory databases always report journal_mode=memory, so use a file-based DB.
        let tempPath = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_wal.db").path
        var fileManager: DatabaseManager? = try DatabaseManager(path: tempPath)
        let journalMode = try fileManager!.dbQueue.read { db in
            try String.fetchOne(db, sql: "PRAGMA journal_mode")
        }
        XCTAssertEqual(journalMode, "wal", "Journal mode should be WAL for file-based databases")

        // Cleanup
        fileManager = nil  // Release database handle before file deletion
        try? FileManager.default.removeItem(atPath: tempPath)
        try? FileManager.default.removeItem(atPath: tempPath + "-wal")
        try? FileManager.default.removeItem(atPath: tempPath + "-shm")
    }

    // MARK: - Edge Cases

    func testInsertEntryWithLargeDataBlob() throws {
        // 1 MB of random bytes
        let size = 1_048_576
        let largeData = Data((0..<size).map { UInt8($0 % 256) })

        var entry = ClipboardEntry(
            timestamp: Date(),
            contentType: .text,
            plainTextContent: largeData,
            richTextContent: nil,
            imageData: nil,
            fileURL: nil,
            sourceApplication: nil,
            metadata: nil
        )
        try dbManager.dbQueue.write { db in
            try entry.insert(db)
        }

        let fetched = try dbManager.dbQueue.read { db in
            try ClipboardEntry.filter(Column("id") == entry.id).fetchOne(db)
        }
        let unwrapped = try XCTUnwrap(fetched)
        let retrieved = try XCTUnwrap(unwrapped.plainTextContent)
        XCTAssertEqual(retrieved.count, size, "Retrieved blob should be 1 MB")
        XCTAssertEqual(retrieved, largeData, "Retrieved blob should be byte-identical")
    }

    func testInsertEntryWithSpecialCharacters() throws {
        let special = "Hello 👋 🌍\nLine 2\tTabbed\r\nWindows\r\"Quoted\" & <XML>"
        try insertTextEntry(text: special)

        let all = try dbManager.dbQueue.read { db in
            try ClipboardEntry.fetchAll(db)
        }
        let content = try XCTUnwrap(all.first?.plainTextContent)
        let retrieved = try XCTUnwrap(String(data: content, encoding: .utf8))
        XCTAssertEqual(retrieved, special, "Special characters should roundtrip accurately")
    }

    // MARK: - Error Handling

    func testDatabaseErrorSetupFailedDescription() throws {
        let underlying = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "disk full"])
        let error = ClipVault.DatabaseError.setupFailed(underlying: underlying)
        XCTAssertTrue(error.localizedDescription.contains("setup failed"))
        XCTAssertTrue(error.localizedDescription.contains("disk full"))
    }

    func testDatabaseErrorDirectoryResolutionFailedDescription() throws {
        let error = ClipVault.DatabaseError.directoryResolutionFailed
        XCTAssertTrue(error.localizedDescription.contains("Application Support"))
    }

    func testInitializerThrowsWithInvalidPath() throws {
        // "/" is a directory, not a writable SQLite file path — should throw
        XCTAssertThrowsError(try DatabaseManager(path: "/")) { error in
            guard let dbError = error as? ClipVault.DatabaseError,
                  case .setupFailed = dbError else {
                XCTFail("Expected ClipVault.DatabaseError.setupFailed, got \(error)")
                return
            }
        }
    }
}
