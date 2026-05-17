//
//  DatabaseSchemaTests.swift
//  ClipVaultTests
//
//  Created by ClipVault.
//

import XCTest
@testable import ClipVault
import GRDB

/// Verifies the GRDB database schema for ClipVault — table structure, column definitions,
/// indexes, FTS5 virtual table, and migration behavior.
final class DatabaseSchemaTests: XCTestCase {

    private var dbManager: DatabaseManager!

    override func setUpWithError() throws {
        try super.setUpWithError()
        dbManager = try DatabaseManager(path: ":memory:")
    }

    override func tearDownWithError() throws {
        dbManager = nil
        try super.tearDownWithError()
    }

    // MARK: - Table Creation

    func testClipboardEntryTableExists() throws {
        let exists = try dbManager.dbQueue.read { db in
            try db.tableExists("clipboardEntry")
        }
        XCTAssertTrue(exists, "clipboardEntry table should exist after migration")
    }

    func testClipboardEntryTableHasCorrectColumns() throws {
        let columns = try dbManager.dbQueue.read { db in
            try db.columns(in: "clipboardEntry")
        }
        let columnNames = Set(columns.map { $0.name })
        let expectedColumns: Set<String> = [
            "id", "timestamp", "contentType", "plainTextContent",
            "richTextContent", "imageData", "fileURL", "sourceApplication", "metadata",
            "plainTextSearchContent", "isPinned"
        ]
        XCTAssertEqual(columnNames, expectedColumns, "clipboardEntry should have exactly 11 expected columns")
    }

    func testPlainTextSearchContentColumnExists() throws {
        let columns = try dbManager.dbQueue.read { db in
            try db.columns(in: "clipboardEntry")
        }
        let columnNames = columns.map { $0.name }
        XCTAssertTrue(columnNames.contains("plainTextSearchContent"),
                       "plainTextSearchContent column should exist in clipboardEntry")
    }

    func testClipboardEntryPrimaryKeyIsAutoIncrement() throws {
        let columns = try dbManager.dbQueue.read { db in
            try db.columns(in: "clipboardEntry")
        }
        guard let idColumn = columns.first(where: { $0.name == "id" }) else {
            XCTFail("id column not found")
            return
        }
        XCTAssertTrue(idColumn.primaryKeyIndex > 0, "id column should be the primary key")
    }

    func testTimestampColumnIsIndexed() throws {
        let indexes = try dbManager.dbQueue.read { db in
            try db.indexes(on: "clipboardEntry")
        }
        let timestampIndexed = indexes.contains { index in
            index.columns.contains("timestamp")
        }
        XCTAssertTrue(timestampIndexed, "timestamp column should have an index")
    }

    func testContentTypeColumnIsIndexed() throws {
        let indexes = try dbManager.dbQueue.read { db in
            try db.indexes(on: "clipboardEntry")
        }
        let contentTypeIndexed = indexes.contains { index in
            index.columns.contains("contentType")
        }
        XCTAssertTrue(contentTypeIndexed, "contentType column should have an index")
    }

    func testColumnsHaveCorrectNullability() throws {
        let columns = try dbManager.dbQueue.read { db in
            try db.columns(in: "clipboardEntry")
        }
        let columnMap = Dictionary(uniqueKeysWithValues: columns.map { ($0.name, $0) })

        // timestamp and contentType must be NOT NULL
        let timestamp = try XCTUnwrap(columnMap["timestamp"], "timestamp column missing")
        XCTAssertTrue(timestamp.isNotNull, "timestamp must be NOT NULL")

        let contentType = try XCTUnwrap(columnMap["contentType"], "contentType column missing")
        XCTAssertTrue(contentType.isNotNull, "contentType must be NOT NULL")

        let isPinned = try XCTUnwrap(columnMap["isPinned"], "isPinned column missing")
        XCTAssertTrue(isPinned.isNotNull, "isPinned must be NOT NULL")

        // All other columns should be nullable
        let nullableColumns = ["id", "plainTextContent", "richTextContent",
                               "imageData", "fileURL", "sourceApplication", "metadata",
                               "plainTextSearchContent"]
        for name in nullableColumns {
            let col = try XCTUnwrap(columnMap[name], "\(name) column missing")
            XCTAssertFalse(col.isNotNull, "\(name) should be nullable")
        }

        // id is auto-increment primary key — it's implicitly NOT NULL but reported as nullable by GRDB
        // because auto-increment PKs are assigned by the engine. We still verify it exists.
    }

    // MARK: - FTS5 Virtual Table

    func testFTS5VirtualTableExists() throws {
        let exists = try dbManager.dbQueue.read { db in
            try db.tableExists("clipboardEntry_fts")
        }
        XCTAssertTrue(exists, "clipboardEntry_fts virtual table should exist")
    }

    func testFTS5HasSearchableColumns() throws {
        // FTS5 virtual table columns are not exposed via db.columns(),
        // so we inspect sqlite_master for the CREATE VIRTUAL TABLE statement.
        let createSQL = try dbManager.dbQueue.read { db in
            try String.fetchOne(db, sql: """
                SELECT sql FROM sqlite_master
                WHERE type = 'table' AND name = 'clipboardEntry_fts'
                """)
        }
        let sql = try XCTUnwrap(createSQL, "FTS5 CREATE statement should exist in sqlite_master")
        XCTAssertTrue(sql.contains("plainTextSearchContent"), "FTS5 should index plainTextSearchContent")
        XCTAssertFalse(sql.contains("plainTextContent"), "FTS5 should NOT index plainTextContent (Data blob)")
        XCTAssertFalse(sql.contains("richTextContent"), "FTS5 should NOT index richTextContent (Data blob)")
        XCTAssertFalse(sql.contains("fileURL"), "FTS5 should NOT index fileURL")
        XCTAssertFalse(sql.contains("sourceApplication"), "FTS5 should NOT index sourceApplication")
    }

    func testFTS5OnlyIndexesPlainTextSearchContent() throws {
        let createSQL = try dbManager.dbQueue.read { db in
            try String.fetchOne(db, sql: """
                SELECT sql FROM sqlite_master
                WHERE type = 'table' AND name = 'clipboardEntry_fts'
                """)
        }
        let sql = try XCTUnwrap(createSQL, "FTS5 CREATE statement should exist in sqlite_master")
        XCTAssertFalse(sql.contains("plainTextContent"),
                        "FTS5 should NOT contain plainTextContent (Data blob)")
        XCTAssertFalse(sql.contains("richTextContent"),
                        "FTS5 should NOT contain richTextContent (Data blob)")
        XCTAssertFalse(sql.contains("fileURL"),
                        "FTS5 should NOT contain fileURL")
        XCTAssertFalse(sql.contains("sourceApplication"),
                        "FTS5 should NOT contain sourceApplication")
        XCTAssertTrue(sql.contains("plainTextSearchContent"),
                       "FTS5 should contain plainTextSearchContent")
    }

    // MARK: - Migration

    func testMigrationV1InitialIsRegistered() throws {
        // GRDB stores applied migration identifiers in the grdb_migrations table.
        let identifiers = try dbManager.dbQueue.read { db in
            try String.fetchAll(db, sql: "SELECT identifier FROM grdb_migrations")
        }
        XCTAssertTrue(
            identifiers.contains("v1_initial"),
            "v1_initial migration should be registered. Found: \(identifiers)"
        )
    }

    func testMigrationRunsWithoutError() throws {
        // The setUp method already ran the migration successfully —
        // if we reach this test, the migration completed without error.
        let exists = try dbManager.dbQueue.read { db in
            try db.tableExists("clipboardEntry")
        }
        XCTAssertTrue(exists, "Migration should create clipboardEntry table")
    }

    func testMigrationIsIdempotent() throws {
        // Running the migration a second time should be a no-op (no throw).
        try dbManager.migrator.migrate(dbManager.dbQueue)

        // Verify the schema is still intact after the second migration run.
        let stillExists = try dbManager.dbQueue.read { db in
            try db.tableExists("clipboardEntry")
        }
        XCTAssertTrue(stillExists, "clipboardEntry table should still exist after idempotent migration")

        let ftsStillExists = try dbManager.dbQueue.read { db in
            try db.tableExists("clipboardEntry_fts")
        }
        XCTAssertTrue(ftsStillExists, "clipboardEntry_fts should still exist after idempotent migration")
    }
}
