# Initial Concept

Build a native Mac application with high security and usability to save and display clipboard content (all popular formats: images, files, text) — with Markdown visualization, large-file pointer references, strict security consciousness, and native support for iPhone clipboard handoff via Universal Clipboard.

## Product Overview

A native macOS clipboard manager that prioritizes security, performance, and developer-centric workflows. The application lives in the menu bar, captures all clipboard content types, and provides a keyboard-driven interface for browsing, searching, and previewing clipboard history. Designed for power users who handle sensitive data and frequently switch between Mac and iPhone.

## Target Audience

### Primary Personas

1. **Power Users & Developers** — Professionals who copy/paste code snippets, markdown, file paths, and configuration blocks dozens of times per day. They need instant search, syntax-aware previews, and zero-friction keyboard access.

2. **Security-Conscious Professionals** — Users handling sensitive data (credentials, API keys, internal documents) who require encrypted storage, sandboxed execution, and the ability to exclude certain content types from being saved.

3. **Cross-Device Workers** — People who frequently switch between Mac and iPhone and rely on Apple's Universal Clipboard for seamless content handoff. The app must detect and preserve clipboard content originating from other devices.

## Core Features (MVP)

### 1. Clipboard History with Search
- Capture every clipboard change (text, images, files, rich text, URLs)
- Smart Deduplication: Prevent redundant entries by comparing content hashes and sources for consecutive copies.
- Store entries with timestamps and source application metadata
- Full-text search across all text-based entries
- Browseable, scrollable history with configurable retention
- Pin/favorite frequently used entries
- **Performance Optimization**: Implemented thread-safe in-memory caching (`ContentCache`) for decrypted content to ensure smooth scrolling and instant retrieval of large text/markdown snippets.

### 2. Rich Content Rendering & Preview
- **Markdown**: Detect markdown content and render it inline with proper formatting (bold, italics, headers) using native `AttributedString`.
- **HTML & RTF**: Support rendering of Rich Text (RTF) and HTML clipboard content, preserving basic styling (colors, fonts, layout) in the history preview.
- **PDF Support**: Detect and render PDF content in the history preview and Detailed Entry View, supporting multi-page scrolling and zooming. Uses robust UTI-based detection (`com.adobe.pdf`) to handle files copied from Finder.
- **Cropped Image Support**: Ensure that images cropped and copied from JPG/PNG sources are detected and previewed correctly in both the list and detailed views.
- **Automatic Previews**: Image and PDF thumbnails are rendered automatically in the history list for instant visibility.
- No separate "preview pane" — content is visible immediately and styled natively.
- **Detailed Entry View**: Double-clicking an entry selects the item and opens a full-screen or large popover view for inspecting the entire content (renders full Markdown/HTML, or lists file contents for folders).

### 3. Vault File Storage

- Configurable "Vault" root location (default: `~/Documents/VaultClip`)
- Automatic date-based organization: files saved into `YYYY-MM` subfolders within the Vault
- Large content (images, large text > 5MB) is saved as organized files instead of DB blobs
- Storage Limit: Default 10GB limit with background auto-trimming (FIFO)
- User-Configurable: Threshold, Root Path, and Storage Limit are all adjustable in Settings.

### 4. iPhone Clipboard Handoff
- Native integration with Apple Universal Clipboard
- Detect clipboard entries originating from iPhone/iPad
- Preserve and display 'iPhone' badge for remote entries
- No additional configuration required — works via iCloud handoff

### 5. Comprehensive User Settings
- **General**: Launch at Login toggle, configurable retention period, and max entry count.
- **Visuals**: UI Zoom/Scaling (80% - 150%) for the history panel.
- **Security**: Configurable auto-purge for sensitive items, custom search redaction rules, and optional Accessibility permissions for automated pasting.
- **Z-Order**: The Settings window must always appear on top of the ClipVault history panel when both are open.
- **Persistence**: All changes applied and saved immediately via a dedicated "Save" button.

## Security Model

### Principles
1. **Least Privilege by Default** — macOS App Sandbox with only explicitly required entitlements. Accessibility permissions for automated pasting are optional and disabled by default.
2. **Data at Rest Protection** — All clipboard history encrypted on disk; decrypted in memory only when displayed
3. **User-Controlled Filtering** — Configurable exclusion rules for sensitive content types and custom regex redaction.
4. **No Network by Default** — Zero network access required; handoff uses system-level iCloud infrastructure
5. **Auto-Expiration**: Mandatory auto-purge for sensitive items (e.g. API keys) with a default 1h TTL, configurable by the user.

### Specific Measures
- **App Sandbox**: Confined to sandbox with no arbitrary file system access
- **Encrypted Storage**: SQLite with CryptoKit-backed AES-256-GCM encryption for history database
- **Content Filtering**: Automatically detect and redact sensitive patterns (Credit Cards, SSNs, Secrets) in the plaintext FTS search index to prevent accidental leakage while maintaining searchability of non-sensitive content.
- **Memory Hygiene**: Clipboard content cleared from app memory when history entry is dismissed
- **No Analytics**: Zero telemetry, zero phoning home, zero third-party SDKs

## User Experience

### Design Pillars
1. **Menu Bar Native** — Status item in the macOS menu bar; one click to open, Escape to close. Never occupies dock space.
2. **Keyboard-First** — Global hotkey to show/hide (default: ⌘⇧V). Full keyboard navigation within the history panel. Arrow keys to browse, Enter to paste, ⌘+number for quick select.
3. **Rich Previews** — Inline previews for images (thumbnails), code (syntax highlighted), markdown (rendered), files (metadata card). No separate "preview pane" — content is visible immediately.
4. **Visual Delight & Eye Candy** — Fully rounded application corners (avoiding sharp edges near the menu bar), stable UI layouts that prevent content shifting on hover, subtle animations for panel transitions, hover-responsive icons, haptic feedback on success/failure, and a polished, semi-transparent frosted glass aesthetic (Vibrancy).
5. **Detailed Inspection** — Double-click any entry to open a detailed inspection view, providing an immersive experience for long documents, code, or complex file listings.
6. **Robust Keyboard Shortcuts** — Deep integration with macOS keyboard event handling ensures that custom shortcuts (e.g., `Cmd+,` for Settings, `Cmd+W` for closing windows) work reliably even when bypassing standard App menu interception.

### Interaction Flow
1. User copies content anywhere (⌘C or right-click → Copy)
2. App captures clipboard change silently in background
3. User invokes clipboard history via global hotkey (⌘⇧V)
4. Panel appears anchored to menu bar with most recent entries
5. User navigates with keyboard arrows or mouse
6. Enter/Click pastes selected entry; Escape dismisses panel
7. Type to filter/search entries in real-time

## Success Criteria

1. Clipboard capture works for text, images, files, and rich text within 100ms of copy
2. History panel opens in under 200ms from hotkey press
3. Search returns results with sub-50ms latency for up to 10,000 entries
4. Zero network connections in default configuration
5. App Store ready: passes App Review with sandbox enabled
6. iPhone clipboard entries appear with device-of-origin label
7. Files >5MB saved to Vault; search index is redacted for sensitive patterns
8. App runs as singleton to prevent duplicate processes
9. Reliable exit via 'Quit' menu or Cmd+Q with background service cleanup
10. "Launch at Login" setting works and defaults to enabled.
11. Clicking "Save" in the Settings window immediately applies and persists all changes.
