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
- **Data at Rest Protection**: All clipboard content is encrypted using AES-256-GCM.
- **On-Demand Decryption**: Content is decrypted only when viewed or copied.
- **Native PDF Previews**: Interactive PDF viewing (scroll/zoom/select) via PDFKit.
- **Cropped Image Detection**: Specific detection and labeling for raw bitmap screenshots and crops.
- **Rich Visuals**: Automatic inline previews for Markdown, code, and images in a beautiful frosted glass UI.
- **Smart Search**: lightning-fast as-you-type search powered by SQLite FTS5.
- **Sensitive Auto-Purge**: Detects and purges credit cards and secrets after a timeout.

## Keyboard Shortcuts

| Shortcut | Action |
| :--- | :--- |
| `⌘⇧V` | Show / Hide History Panel (Configurable) |
| `↑` / `↓` | Navigate History |
| `Enter` | Paste Selected Entry |
| `⌥ + Enter` | Paste as Plain Text |
| `⌘ + 1-9` | Quick Paste nth Entry |
| `⌘ + C` | Copy Selected Entry back to System Clipboard |
| `⌘ + F` | Focus Search Bar |
| `⌘ + W` | Close Active Child Window (Settings/Details) or Dismiss Panel |
| `⌘ + ⌫` | Delete Selected Entry |
| `⌘ + ,` | Open Settings |
| `Esc` | Clear Search or Dismiss Panel |

## Installation
1. Download the latest release from the [Releases page](https://github.com/mechatroNick/ClipVault/releases).
2. Drag `ClipVault.app` to your `/Applications` folder.
3. Open the app. The clipboard icon will appear in your menu bar.

## Release Notes

### v1.5.0 (App Polish & New Features)
- **Settings Window Overhaul**: Settings now features a dedicated **Appearance tab** alongside General, Security, and About. UI Zoom has moved to Appearance, keeping General focused on clipboard behavior.
- **Customizable Global Hotkey**: The shortcut to open ClipVault (`⌘⇧V` by default) is now fully customizable. Click the shortcut in Settings → Appearance to record a new combination.
- **Privacy Ignore List**: A new user-configurable ignore list in Settings → Security silently blocks clipboard changes originating from nominated apps. Defaults to 1Password, Keychain Access, and Bitwarden — providing a second privacy layer alongside the existing Concealed Type filter.
- **Visual Content Indicators**: Added distinct, beautifully integrated SF Symbol icons for Code Snippets, Plain Text, Images, and Files to the history list for quick scanning.
- **Empty State Delight**: A new animated illustration welcomes you when your Vault is empty, creating a more polished first impression.
- **Entry Insertion Animation**: New clipboard entries now appear with a smooth slide-down and fade-in animation in the history panel.
- **Paste as Plain Text Button**: Added a dedicated quick-action button on each entry row to paste content as plain text, stripping any rich formatting instantly.
- **Filter by Pinned/Favorites**: A new toggle next to the search bar lets you instantly filter the history list to show only your pinned/favorited entries.

### v1.4.3 (UI Refinements)
- **Rounded UI Corners**: Enhanced the visual polish by applying fully rounded corners to the main history panel, resolving an edge case where macOS rendered sharp top corners near the menu bar.
- **Timestamp Realignment**: Improved readability by moving the creation timestamp to the far right of the row, anchoring it next to the action buttons.
### v1.4.2 (UI Polish & Shortcuts)
- **Settings Shortcut Fix**: Resolved an issue where the `Cmd+,` keyboard shortcut was intercepted by the default App menu, allowing it to correctly open the custom Settings sub-window when the history panel is focused.
- **Layout Stability**: Fixed a visual bug where hovering over a history item caused the text preview to unexpectedly wrap and change size due to dynamically inserted action buttons.
### v1.4.1 (Search & Memory Stability)
- **FTS Index Stability**: Fixed an issue where very long text snippets could be truncated in the search index, ensuring full-text search works for clips of any size.
- **Cache Memory Limits**: Enforced a strict maximum memory threshold for the decrypted content cache, preventing unbounded memory growth during heavy usage.

### v1.4.0 (Performance & Reliability)
- **Decrypted Content Cache**: Implemented a thread-safe `ContentCache` to prevent redundant decryptions of large text and markdown strings, significantly improving scroll performance in the history list.
- **Improved Test Coverage**: Added heuristic tests for Markdown/Code detection and verified pagination logic, bringing the project closer to 100% coverage for core services.
- **Production Hardening**: Removed debug logging and performed a comprehensive security audit of the recent feature additions.

### v1.3.6 (PDF UI Polish)
- **Resolved Double Scroll Bars**: Fixed a UI issue where PDFs in the detailed view displayed redundant scroll bars by correctly managing nested scroll views.
- **Improved PDF Layout**: PDFs now correctly utilize the full available window space in the detailed entry view.

### v1.3.5 (PDF Thumbnail Stability)
- **PDF Search Thumbnails**: PDF entries in search results now correctly display thumbnails by ensuring on-demand decryption of PDF content.
- **Improved Vaulting**: Corrected vaulting and decryption logic for PDF and Cropped Image types, ensuring data integrity for large files.
- **PDF Icon**: Added a distinct icon for PDF entries in the history list.

### v1.3.4 (Shortcut Stability)
- **Cmd+F Refocus**: Pressing `⌘F` while the history panel is open now reliably refocuses the search bar, even if it's already visible.
- **Robust Cmd+W**: Improved `⌘W` logic to ensure it reliably closes the main history panel as well as all child windows (Settings, Details).

### v1.3.3 (Shortcut Improvements)
- **Cmd+W Support**: Added the `⌘W` keyboard shortcut to close child windows (Settings, Detailed View) or dismiss the history panel without quitting the application.

### v1.3.2 (Selection & PDF Polish)
- **Selection on Double-Click**: Double-clicking an entry now automatically selects it in the history list before opening the detailed view.
- **Robust PDF Detection**: Improved PDF detection logic to use both file extensions and Uniform Type Identifiers (UTIs) for more reliable previews.
- **Improved PDF Capture**: Added additional logging and verification to the PDF capture pipeline.

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
**Requirements**: Xcode 15.3+, macOS 14.0+

1. Clone the repository:
   ```bash
   git clone git@github.com:mechatroNick/ClipVault.git
   ```
2. Open `ClipVault.xcodeproj` in Xcode.
3. Select the `ClipVault` scheme and run (⌘R).

## Documentation
- [Technical Architecture](conductor/archive/maintenance-release-prep_20260520/TECHNICAL_ARCHITECTURE.md)
- [Developer API Reference](conductor/archive/maintenance-release-prep_20260520/API_REFERENCE.md)
- [User Guide](conductor/archive/maintenance-release-prep_20260520/USER_GUIDE.md)

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
