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
- Store entries with timestamps and source application metadata
- Full-text search across all text-based entries
- Browseable, scrollable history with configurable retention
- Pin/favorite frequently used entries

### 2. Markdown Rendering & Preview
- Detect markdown content and render it inline with proper formatting
- Syntax highlighting for code blocks within markdown
- Toggle between raw source and rendered preview
- Support for common markdown extensions (tables, task lists, footnotes)

### 3. Vault File Storage
- Configurable "Vault" root location (default: `~/Documents/VaultClip`)
- Automatic date-based organization: files saved into `YYYY-MM` subfolders within the Vault
- Large content (images, large text > 5MB) is saved as organized files instead of DB blobs
- For files copied in Finder: store relative path reference to original; provide option to "Archive to Vault"
- Vault directory structure created automatically on first save of a given month

### 4. iPhone Clipboard Handoff
- Native integration with Apple Universal Clipboard
- Detect clipboard entries originating from iPhone/iPad
- Preserve and display device-of-origin metadata
- No additional configuration required — works via iCloud handoff

## Security Model

### Principles
1. **Least Privilege by Default** — macOS App Sandbox with only explicitly required entitlements
2. **Data at Rest Protection** — All clipboard history encrypted on disk; decrypted in memory only when displayed
3. **User-Controlled Filtering** — Configurable exclusion rules for sensitive content types
4. **No Network by Default** — Zero network access required; handoff uses system-level iCloud infrastructure

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
4. **macOS Native** — SwiftUI interface following Apple HIG. Native context menus, haptic feedback, dark mode support, and VoiceOver accessibility.

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
