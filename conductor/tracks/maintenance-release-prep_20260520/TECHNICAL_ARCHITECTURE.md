# Technical Architecture

## Overview
ClipVault is designed as an offline-first, highly secure macOS clipboard manager. Its primary architectural goals are **data security** (encryption at rest), **performance** (minimal main-thread blocking, efficient search), and **low resource utilization** (on-demand decryption and caching).

## Core Components

### 1. Data Storage & Search (`DatabaseManager` & `ClipboardRepository`)
- **Database Engine**: Uses **GRDB.swift** to interact with a local SQLite database.
- **WAL Mode**: Write-Ahead Logging is enabled to allow concurrent read and write operations, preventing UI hitches during intensive background captures.
- **Full-Text Search (FTS5)**:
  - An FTS5 virtual table (`clipboardEntry_fts`) is synchronized with the main `clipboardEntry` table.
  - **Optimization**: Search utilizes **prefix matching** (`FTS5Pattern(matchingAllPrefixesIn:)`) to provide instant, as-you-type results.
  - **Security**: Sensitive content (e.g., credit cards) is redacted *before* being inserted into the plaintext search index, ensuring secrets are not discoverable via database inspection.

### 2. Security & Encryption (`EncryptionService` & `KeychainManager`)
- **Key Management**: A single 256-bit `SymmetricKey` is generated on first launch and stored securely in the macOS Keychain (`KeychainManager`).
- **Encryption at Rest**: All clipboard content (plain text, rich text, images) is encrypted using **AES-256-GCM** before being written to disk.
- **On-Demand Decryption**: The application decrypts content *only* when it is required for display in the UI (e.g., when a user hovers over an entry or it becomes visible in the list). Decrypted data is held in memory temporarily and never cached to disk.

### 3. Large File Vaulting (`VaultManager`)
To prevent database bloat, payloads exceeding a configurable threshold (default 5MB) bypass the SQLite database.
- Large data is encrypted independently and stored as a distinct file on the filesystem (the "Vault").
- The database stores a reference (`fileURL`) to the vaulted file.
- This ensures database queries remain fast and backup operations are manageable.

### 4. Background Monitoring (`PasteboardMonitor` & `ClipboardCaptureService`)
- The `PasteboardMonitor` polls the system `NSPasteboard` change count on a background thread.
- When a change is detected, `ClipboardCaptureService`:
  1. Detects the semantic content type (e.g., `text`, `image`, `url`).
  2. Computes a SHA-256 hash of the content for rapid deduplication (preventing consecutive duplicate entries from the same source application).
  3. Secures the payload via `ClipboardRepository`.

### 5. UI and Presentation (`MenuBarController` & `HistoryPanelView`)
- **Architecture**: Follows an MVVM pattern (`ClipboardViewModel`).
- **Performance**:
  - The UI uses **lazy loading** and **pagination**; it fetches items in batches (e.g., 50 at a time) and loads more as the user scrolls.
  - Decrypted image thumbnails are stored in a size-limited `NSCache` (`ThumbnailCache`) to prevent repeated expensive decryption operations during scrolling.
- **State Updates**: Leverages GRDB's `ValueObservation` to reactively update the UI whenever the underlying database changes (e.g., on new capture or background purge).

## Privacy-First Features
- **Accessibility Opt-in**: The high-privilege Accessibility permission required to simulate a `⌘V` keypress (for automated pasting) is disabled by default. Users must explicitly enable `simulatePasteEnabled` in settings.
- **Auto-Purging**: Items flagged as sensitive by the `SensitiveContentFilter` are automatically purged from the database after a configurable Time-To-Live (TTL).
