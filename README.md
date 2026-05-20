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

## Security Model

```text
+-----------------------------------------------------------+
|                   LAYERED SECURITY MODEL                  |
+-----------------------------------------------------------+
| [ USER SPACE ]                                            |
|       |                                                   |
|       v  (1) APP SANDBOX                                  |
| +-------------------------------------------------------+ |
| | NO NETWORK ACCESS | NO FILESYSTEM ACCESS (Except App) | |
| +-------------------------------------------------------+ |
|       |                                                   |
|       v  (2) ON-DEMAND DECRYPTION                         |
| +-------------------------------------------------------+ |
| | Plaintext exists ONLY in RAM while viewing              | |
| +-------------------------------------------------------+ |
|       |                                                   |
|       v  (3) ENCRYPTION AT REST                           |
| +-------------------------------------------------------+ |
| | AES-256-GCM | Master Key in macOS Keychain            | |
| +-------------------------------------------------------+ |
|       |                                                   |
|       v  (4) OFFLINE STORAGE                              |
| +-------------------------------------------------------+ |
| | Local SQLite DB | Local File Vault                    | |
| +-------------------------------------------------------+ |
+-----------------------------------------------------------+
```

ClipVault is built on the Principle of Least Privilege. It requires zero network permissions and uses the macOS Keychain for hardware-backed key security.

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

### v1.3.1 (UI Polish & Workflow)
- **Auto-Selection**: Pressing the copy button on an entry now automatically selects that entry in the history list.
- **Workflow Formalization**: Documented the full release protocol (test, version, commit, tag, push, deploy) in `workflow.md`.

### v1.3.0 (Stability & PDF Fixes)
- **PDF Preview Fixed**: Resolved an issue where PDF files copied from Finder were not correctly captured for preview.
- **Copy Shortcut**: Added support for `⌘C` in the history panel to copy the currently selected entry.
- **Workflow Improvements**: Formalized the release process and local deployment protocol in the project documentation.

### v1.2.0 (Advanced Media Previews & Window Management)
- **Native PDF Integration**: View PDFs directly in the detailed entry view with full scroll, zoom, and text selection capabilities. First-page thumbnails are automatically generated for the history list.
- **Enhanced Image Detection**: Added specific detection and labeling for cropped image data (screenshots/crops) across PNG, JPG, and TIFF formats.
- **Improved Window Management**: Enforced a child-window relationship for Settings and Detailed views, ensuring they always stay on top of the main panel.
- **UI Expansion**: Increased the default history panel width by 20% (to 420pt) for better preview visibility.
- **Bug Fixes**: Resolved issues with Settings interaction and history duplication during self-copy.

### v1.1.0 (UI Fixes & Markdown Rendering)
- **Rich Text Previews**: The history list now displays up to 3 lines of preview text for Markdown, HTML, and code entries.
- **Detailed Entry View**: Double-click any entry to open a full-content inspector. For folders, this view lists all contained file names.
- **Strict Syntax Validation**: Implemented safe rendering for Markdown and HTML with automatic fallback to plain text if syntax is broken.
- **Auto-Preview**: Image thumbnails are now decrypted and displayed automatically in the list without requiring a hover action.
- **Vault Auto-Creation**: The `~/Documents/VaultClip` directory is now safely created on first launch if it doesn't exist.
- **Build Info**: Added build timestamp to the About section in Settings.

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
