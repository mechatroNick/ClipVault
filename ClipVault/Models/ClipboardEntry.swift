//
//  ClipboardEntry.swift
//  ClipVault
//
//  Created by ClipVault.
//

import Foundation
import GRDB

/// Represents a single clipboard history entry stored in the local GRDB database.
///
/// Each entry captures the content type, encrypted content blobs, and metadata
/// necessary for full clipboard history search and restoration. Encrypted fields
/// (plain text, rich text, image data, metadata) are stored as opaque `Data` blobs
/// and decrypted at the service layer before presentation.
struct ClipboardEntry: Codable, FetchableRecord, MutablePersistableRecord {

    // MARK: - Table Metadata

    static let databaseTableName = "clipboardEntry"

    // MARK: - Properties

    /// When the clipboard content was captured. Indexed, not `NULL`.
    let timestamp: Date

    /// The type of clipboard content. Indexed, not `NULL`.
    ///
    /// Values: `"text"`, `"image"`, `"file"`, `"url"`, `"html"`, `"rtf"`, `"other"`.
    let contentType: String

    /// Auto-incremented primary key. `nil` before first insert;
    /// populated by `didInsert(_:)` after a successful database write.
    var id: Int64?

    /// Encrypted UTF-8 plain text content.
    var plainTextContent: Data?

    /// Encrypted rich text (RTF or HTML) content.
    var richTextContent: Data?

    /// Encrypted image data (PNG or TIFF representation).
    var imageData: Data?

    /// Plaintext search content populated at capture time.
    ///
    /// When content is encrypted, this column stores the plaintext string
    /// representation extracted before encryption so the FTS5 index can
    /// search clipboard history without decrypting the Data blobs.
    var plainTextSearchContent: String?

    /// File path for large clipboard content stored externally on disk.
    var fileURL: String?

    /// Bundle identifier of the source application, used for handoff tracking.
    ///
    /// Example: `"com.apple.Safari"` when content originates from an iPhone
    /// via Universal Clipboard.
    var sourceApplication: String?

    /// Encrypted JSON metadata blob (source app info, pasteboard change count, etc.).
    var metadata: Data?

    /// The title of the active window when the content was captured.
    var windowTitle: String?

    /// The name of the device where the content originated.
    var deviceName: String?

    /// Hash of the content for deduplication.
    var contentHash: String?

    /// Whether the entry contains sensitive information.
    var isSensitive: Bool = false

    /// When the entry should be automatically purged.
    var expiryDate: Date?

    /// Whether the entry is pinned to prevent auto-purge.
    var isPinned: Bool = false

    /// Whether the full content is stored in the encrypted file vault.
    var isVaultStored: Bool = false

    /// Whether the entry originated from a remote device via Universal Clipboard.
    var isRemote: Bool = false

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case timestamp
        case contentType
        case id
        case plainTextContent
        case richTextContent
        case imageData
        case plainTextSearchContent
        case fileURL
        case sourceApplication
        case metadata
        case windowTitle
        case deviceName
        case contentHash
        case isSensitive
        case expiryDate
        case isPinned
        case isVaultStored
        case isRemote
    }

    // MARK: - MutablePersistableRecord

    /// Captures the auto-incremented row ID after a successful database insert.
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

// MARK: - Columns

extension ClipboardEntry {
    /// Type-safe column references for use in GRDB query expressions.
    ///
    /// Usage: `ClipboardEntry.Columns.timestamp` in `filter`, `order`, etc.
    enum Columns {
        static let timestamp = Column(CodingKeys.timestamp)
        static let contentType = Column(CodingKeys.contentType)
        static let id = Column(CodingKeys.id)
        static let plainTextContent = Column(CodingKeys.plainTextContent)
        static let richTextContent = Column(CodingKeys.richTextContent)
        static let imageData = Column(CodingKeys.imageData)
        static let plainTextSearchContent = Column(CodingKeys.plainTextSearchContent)
        static let fileURL = Column(CodingKeys.fileURL)
        static let sourceApplication = Column(CodingKeys.sourceApplication)
        static let metadata = Column(CodingKeys.metadata)
        static let windowTitle = Column(CodingKeys.windowTitle)
        static let deviceName = Column(CodingKeys.deviceName)
        static let contentHash = Column(CodingKeys.contentHash)
        static let isSensitive = Column(CodingKeys.isSensitive)
        static let expiryDate = Column(CodingKeys.expiryDate)
        static let isPinned = Column(CodingKeys.isPinned)
        static let isVaultStored = Column(CodingKeys.isVaultStored)
        static let isRemote = Column(CodingKeys.isRemote)
    }
}
