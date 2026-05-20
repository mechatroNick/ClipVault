# ClipVault

ClipVault is a highly secure, offline-first macOS clipboard manager. It lives in your menu bar and encrypts your entire clipboard history using AES-256-GCM.

## Features
- **Zero-Trust Architecture**: Operates entirely offline within the macOS App Sandbox.
- **Data at Rest Protection**: All clipboard content (text, images, files, rich text) is encrypted on disk.
- **On-Demand Decryption**: Content is decrypted only when viewed, never cached in plaintext.
- **Rich Previews**: Beautiful inline previews for Markdown, code, images, and files.
- **Smart Search**: Fast, paginated prefix-matching search powered by SQLite FTS5.
- **Sensitive Auto-Purge**: Automatically detects and deletes sensitive strings (like credit cards).
- **Keyboard Driven**: Fully navigable via keyboard shortcuts.

## Installation
1. Download the latest release from the [Releases page].
2. Drag `ClipVault.app` to your `/Applications` folder.
3. Open the app. The clipboard icon will appear in your menu bar.

## Building from Source
**Requirements**: Xcode 15+, macOS 14.0+

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/clipboard-mac-app.git
   ```
2. Open `ClipVault.xcodeproj` in Xcode.
3. Select the `ClipVault` scheme and run (⌘R).

## Documentation
For more detailed information, please refer to the documentation in the `conductor/tracks/maintenance-release-prep_20260520/` directory:
- [Technical Architecture](conductor/tracks/maintenance-release-prep_20260520/TECHNICAL_ARCHITECTURE.md)
- [Developer API Reference](conductor/tracks/maintenance-release-prep_20260520/API_REFERENCE.md)
- [User Guide](conductor/tracks/maintenance-release-prep_20260520/USER_GUIDE.md)

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
