//
//  DatabaseManager.swift
//  ClipVault
//
//  Created by ClipVault.
//

import Foundation
import GRDB

// MARK: - DatabaseError

/// Errors that can occur during database setup and operation.
enum DatabaseError: LocalizedError {
    /// The database queue could not be created or configured.
    case setupFailed(underlying: Error)

    /// The Application Support directory could not be resolved.
    case directoryResolutionFailed

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .setupFailed(let error):
            return "Database setup failed: \(error.localizedDescription)"
        case .directoryResolutionFailed:
            return "Could not locate or create the Application Support directory."
        }
    }
}

// MARK: - DatabaseManager

/// Manages the GRDB database lifecycle for ClipVault.
///
/// Provides a shared `DatabaseQueue` configured with WAL mode and the
/// FTS5-backed `clipboardEntry` table. The database lives at
/// `~/Library/Application Support/ClipVault/clipvault.db` and is wiped
/// automatically on schema changes during development.
final class DatabaseManager {

    // MARK: - Singleton

    /// The shared database manager.
    ///
    /// Wraps `DatabaseManager()` in a `do/catch` block and terminates the
    /// process with a clear error message if the database cannot be set up.
    /// The application cannot function without a working database.
    static let shared: DatabaseManager = {
        do {
            return try DatabaseManager()
        } catch {
            fatalError("Failed to initialize database: \(error.localizedDescription)")
        }
    }()

    // MARK: - Properties

    /// The GRDB database queue backing all read/write operations.
    let dbQueue: DatabaseQueue

    /// The migration registry for schema versioning.
    ///
    /// Exposed for test inspection so test suites can verify which migrations
    /// are registered without executing them.
    var migrator: DatabaseMigrator

    // MARK: - Initialization

    /// Creates a database manager targeting a specific path.
    ///
    /// Use `":memory:"` or a temporary URL for unit tests.
    ///
    /// - Parameter path: The filesystem path to the SQLite database file,
    ///   or `":memory:"` for an in-memory database.
    /// - Throws: `DatabaseError.setupFailed` if the queue cannot be opened
    ///   or migrations cannot be applied.
    init(path: String) throws {
        var config = Configuration()
        config.prepareDatabase { db in
            try db.execute(sql: "PRAGMA journal_mode=WAL")
        }

        do {
            dbQueue = try DatabaseQueue(path: path, configuration: config)
        } catch {
            throw DatabaseError.setupFailed(underlying: error)
        }

        migrator = DatabaseMigrator()
        migrator.eraseDatabaseOnSchemaChange = true

        Self.registerMigrations(with: &migrator)

        do {
            try migrator.migrate(dbQueue)
        } catch {
            throw DatabaseError.setupFailed(underlying: error)
        }
    }

    /// Convenience initializer that resolves the database path within the
    /// application sandbox.
    ///
    /// The database lives at `~/Library/Application Support/ClipVault/clipvault.db`.
    /// Intermediate directories are created automatically if they do not exist.
    ///
    /// - Throws: `DatabaseError.directoryResolutionFailed` if the Application
    ///   Support directory cannot be resolved, or `DatabaseError.setupFailed`
    ///   if the queue cannot be opened.
    convenience init() throws {
        guard let appSupport = try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true)
        else {
            throw DatabaseError.directoryResolutionFailed
        }

        let directory = appSupport.appendingPathComponent(
            "ClipVault", isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true)

        let dbURL = directory.appendingPathComponent("clipvault.db")
        try self.init(path: dbURL.path)
    }

    // MARK: - Queries

    /// Inserts a clipboard entry into the database and assigns its auto-generated `id`.
    ///
    /// After a successful insert, the entry's `id` property is updated to reflect
    /// the database-assigned primary key.
    ///
    /// - Parameter entry: The clipboard entry to insert. Mutated in place so `id`
    ///   is populated on return.
    /// - Throws: GRDB errors if the insert fails (e.g., constraint violation).
    func insert(_ entry: inout ClipboardEntry) throws {
        try dbQueue.write { db in
            try entry.insert(db)
        }
    }

    /// Returns all clipboard entries in the database, ordered by timestamp
    /// descending (most recent first).
    ///
    /// - Returns: An array of `ClipboardEntry` values, or an empty array if no
    ///   entries exist.
    /// - Throws: GRDB errors if the read fails.
    func fetchAll() throws -> [ClipboardEntry] {
        try dbQueue.read { db in
            try ClipboardEntry
                .order(Column("timestamp").desc)
                .fetchAll(db)
        }
    }

    /// Performs a full-text search against clipboard entry plain-text content.
    ///
    /// The query is tokenized using `FTS5Pattern(matchingAllTokensIn:)`, which
    /// splits the query into individual tokens and requires all of them to match.
    /// If the query cannot be parsed into a valid FTS5 pattern, an empty array
    /// is returned.
    ///
    /// Results are ordered by timestamp descending (most recent first).
    ///
    /// - Parameter query: A free-text search string.
    /// - Returns: Matching entries, or an empty array if no matches are found
    ///   or the query is malformed.
    /// - Throws: GRDB errors if the read fails.
    func search(_ query: String) throws -> [ClipboardEntry] {
        guard let pattern = FTS5Pattern(matchingAllTokensIn: query) else {
            return []
        }
        return try dbQueue.read { db in
            try ClipboardEntry.fetchAll(db, sql: """
                SELECT clipboardEntry.* FROM clipboardEntry
                JOIN clipboardEntry_fts ON clipboardEntry_fts.rowid = clipboardEntry.rowid
                WHERE clipboardEntry_fts MATCH ?
                ORDER BY clipboardEntry.timestamp DESC
                """, arguments: [pattern])
        }
    }

    // MARK: - Migrations

    /// Registers all schema migrations with the given migrator.
    ///
    /// - Parameter migrator: The migrator to register migrations on.
    private static func registerMigrations(with migrator: inout DatabaseMigrator) {
        migrator.registerMigration("v1_initial") { db in
            try db.create(table: "clipboardEntry") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("timestamp", .date).notNull().indexed()
                t.column("contentType", .text).notNull().indexed()
                t.column("plainTextContent", .blob)
                t.column("richTextContent", .blob)
                t.column("imageData", .blob)
                t.column("plainTextSearchContent", .text)
                t.column("fileURL", .text)
                t.column("sourceApplication", .text)
                t.column("metadata", .blob)
            }

            try db.create(virtualTable: "clipboardEntry_fts", using: FTS5()) { t in
                t.synchronize(withTable: "clipboardEntry")
                t.column("plainTextSearchContent")
            }
        }
        
        migrator.registerMigration("v2_add_pinned") { db in
            try db.alter(table: "clipboardEntry") { t in
                t.add(column: "isPinned", .boolean).notNull().defaults(to: false)
            }
        }
        
        migrator.registerMigration("v3_add_isVaultStored") { db in
            try db.alter(table: "clipboardEntry") { t in
                t.add(column: "isVaultStored", .boolean).notNull().defaults(to: false)
            }
        }
        
        migrator.registerMigration("v4_add_isRemote") { db in
            try db.alter(table: "clipboardEntry") { t in
                t.add(column: "isRemote", .boolean).notNull().defaults(to: false)
            }
        }
        
        migrator.registerMigration("v5_add_metadata_columns") { db in
            try db.alter(table: "clipboardEntry") { t in
                t.add(column: "windowTitle", .text)
                t.add(column: "deviceName", .text)
            }
        }

        migrator.registerMigration("v6_add_content_hash") { db in
            try db.alter(table: "clipboardEntry") { t in
                t.add(column: "contentHash", .text).indexed()
            }
        }
    }
}
