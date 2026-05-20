# Developer API Reference

This document outlines the primary public interfaces for the core services within the ClipVault application.

## 1. Storage & Retrieval

### `ClipboardRepository`
The central coordinator for saving, fetching, and decrypting clipboard entries.

- `func save(_ entry: inout ClipboardEntry) throws`
  - Encrypts content, handles large file vaulting, extracts FTS previews, performs sensitive content detection, and saves the entry to the database. Populates the `id` field on the `inout` parameter upon success.
- `func fetchAll() throws -> [ClipboardEntry]`
  - Retrieves all entries, ordered by timestamp (newest first). Note: Returned entries contain *encrypted* payloads.
- `func search(_ query: String, limit: Int = 100, offset: Int = 0) throws -> [ClipboardEntry]`
  - Performs a prefix-matched FTS5 search against the `clipboardEntry_fts` virtual table.
- `func observeEntries(limit: Int) -> AsyncStream<[ClipboardEntry]>`
  - Returns an `AsyncStream` that yields a new array of entries whenever the underlying database table changes.
- `func decryptContent(for entry: ClipboardEntry) throws -> ClipboardEntry`
  - Takes an entry with encrypted `Data` blobs and returns a new `ClipboardEntry` instance with the `plainTextContent`, `richTextContent`, or `imageData` decrypted and available in memory.
- `func purgeExpired(olderThan timeInterval: TimeInterval) throws`
  - Deletes unpinned entries older than the given interval, as well as sensitive entries that have passed their `expiryDate`.

### `DatabaseManager`
Manages the GRDB SQLite connection and schema migrations.

- `static let shared: DatabaseManager`
  - The singleton instance connected to the App Support directory.
- `let dbQueue: DatabaseQueue`
  - The underlying GRDB connection queue, configured with WAL mode.
- `func search(_ query: String, limit: Int, offset: Int) throws -> [ClipboardEntry]`
  - Executes the raw FTS5 SQL query.

## 2. Security

### `EncryptionService`
Handles AES-GCM operations.

- `func encrypt(plaintext: Data, using key: SymmetricKey) throws -> EncryptedPackage`
  - Encrypts data and returns a package containing the nonce, ciphertext, and authentication tag.
- `func decrypt(package: EncryptedPackage, using key: SymmetricKey) throws -> Data`
  - Validates and decrypts the package using the provided key.

### `KeychainProtocol` / `KeychainManager`
Manages the symmetric key required for database encryption.

- `func retrieveKey() throws -> SymmetricKey?`
- `func generateAndStoreKey() throws -> SymmetricKey`

## 3. System Interaction

### `PasteService`
Handles writing to `NSPasteboard` and simulating key events.

- `func preparePasteboard(for entry: ClipboardEntry) async throws`
  - Clears the system pasteboard and writes the appropriate data types (e.g., `.string`, `.tiff`, `.rtf`, `.fileURL`) based on the entry's `ClipboardContentType`.
- `func simulatePaste() async`
  - If `simulatePasteEnabled` is true in Settings, uses `CGEvent.post(tap: .cghidEventTap)` to simulate a `⌘V` keystroke.

### `ClipboardCaptureService`
Monitors the pasteboard and processes incoming changes.

- `func start()`
  - Begins listening to the `PasteboardMonitor` stream on a background task.
- `func captureCurrentPasteboard() async`
  - Analyzes the current pasteboard via `ContentTypeDetector`, computes a SHA-256 hash to prevent duplicate captures from the same source, and hands the payload to `ClipboardRepository` for storage.
