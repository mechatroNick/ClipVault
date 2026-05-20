# ClipVault

ClipVault is a highly secure, offline-first macOS clipboard manager. It lives in your menu bar and encrypts your entire clipboard history using AES-256-GCM.

## Architecture

```text
+-------------------------------------------------------------+
|                     macOS App Sandbox                       |
|                                                             |
|  +----------------+    +---------------------------------+  |
|  |                |    |         ClipVault Core          |  |
|  |  System        |--->|                                 |  |
|  |  NSPasteboard  |    |  +---------------------------+  |  |
|  |                |<---|  | ClipboardCaptureService   |  |  |
|  +----------------+    |  +---------------------------+  |  |
|                        |                |                |  |
|                        |                v                |  |
|                        |  +---------------------------+  |  |
|  +----------------+    |  |   ClipboardRepository     |  |  |
|  | macOS Keychain |<-->|  |  (Encryption / Decryption)|  |  |
|  +----------------+    |  +---------------------------+  |  |
|                        |                |                |  |
|                        |        +-------+-------+        |  |
|                        |        |               |        |  |
|                        |        v               v        |  |
|                        |  +-----------+   +-----------+  |  |
|                        |  | SQLite DB |   | Vault     |  |  |
|                        |  | w/ FTS5   |   | Manager   |  |  |
|                        |  | (Metadata,|   | (Large    |  |  |
|                        |  |  Text)    |   |  Files/   |  |  |
|                        |  +-----------+   |  Images)  |  |  |
|                        |                  +-----------+  |  |
|                        +---------------------------------+  |
+-------------------------------------------------------------+
```

ClipVault guarantees privacy through an offline-only architecture. Large blobs (like images) are "vaulted" as encrypted files to keep the main SQLite database fast, while the `FTS5` virtual table ensures instant, as-you-type search performance.

## Features
- **Zero-Trust Architecture**: Operates entirely offline within the macOS App Sandbox.
- **Data at Rest Protection**: All clipboard content (text, images, files, rich text) is encrypted on disk.
- **On-Demand Decryption**: Content is decrypted only when viewed, never cached in plaintext.
- **Rich Previews**: Beautiful inline previews for Markdown, code, images, and files.
- **Smart Search**: Fast, paginated prefix-matching search powered by SQLite FTS5.
- **Sensitive Auto-Purge**: Automatically detects and deletes sensitive strings (like credit cards).
- **Keyboard Driven**: Fully navigable via keyboard shortcuts.
- **Optional Accessibility**: Auto-paste is strictly opt-in, preserving least-privilege defaults.

## Installation
1. Download the latest release from the [Releases page].
2. Drag `ClipVault.app` to your `/Applications` folder.
3. Open the app. The clipboard icon will appear in your menu bar.

## Release Notes

### v1.0.0 (Initial Release)
- Safely store your clipboard history with AES-256 encryption.
- Instantly search past clips with lightning-fast prefix matching and debouncing.
- Preview images, formatted markdown, and code snippets directly in the menu bar.
- Rest easy with automatic purging of sensitive information.
- Fully sandboxed and offline—your data never leaves your Mac.
- Custom SwiftUI `NSPanel` implementation with a beautiful frosted glass aesthetic.

## Building from Source
**Requirements**: Xcode 15+, macOS 14.0+

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/clipboard-mac-app.git
   ```
2. Open `ClipVault.xcodeproj` in Xcode.
3. Select the `ClipVault` scheme and run (⌘R).

## Documentation
For more detailed information, please refer to the documentation in the `conductor/archive/maintenance-release-prep_20260520/` directory:
- [Technical Architecture](conductor/archive/maintenance-release-prep_20260520/TECHNICAL_ARCHITECTURE.md)
- [Developer API Reference](conductor/archive/maintenance-release-prep_20260520/API_REFERENCE.md)
- [User Guide](conductor/archive/maintenance-release-prep_20260520/USER_GUIDE.md)

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
