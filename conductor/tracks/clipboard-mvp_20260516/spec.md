# Specification: Clipboard MVP

## Track ID
`clipboard-mvp_20260516`

## Overview
Thin vertical slice through all layers of the clipboard manager: pasteboard monitoring → encrypted persistence → menu bar UI → paste back. Security foundations included (sandbox, encryption, no network). All features keyboard-accessible. iPhone handoff and advanced content filtering deferred.

## Functional Requirements

### FR1: Clipboard Capture
- Monitor NSPasteboard for changes using change count polling
- Detect content types: plain text, rich text (RTF/RTFD), images (TIFF/PNG), file URLs, string URLs
- Capture within 100ms of clipboard change
- Generate unique entry ID with timestamp and source application metadata
- Do NOT capture content from the app itself (filter self-copies)

### FR2: Content Type Detection
- Classify each clipboard item into one of: text, code, markdown, image, file, url, unknown
- Detect markdown via heuristics (leading `#`, `*`, `-`, backtick fences, `[]()` links)
- Detect code via heuristics (indentation patterns, common keywords, absence of prose)
- Store content type alongside entry for optimized preview rendering

### FR3: Encrypted Persistence
- Store all clipboard entries in SQLite database via GRDB.swift
- Encrypt database file at rest using AES-GCM (CryptoKit)
- Generate and store encryption key in macOS Keychain (kSecAttrAccessible.whenUnlocked)
- Enable FTS5 full-text search index on text content
- Schema supports: id, content (encrypted blob), contentType, plainTextPreview, timestamp, sourceAppBundleId, isPinned, filePath (nullable for file references)

### FR4: Large File Handling
- Configurable size threshold (default: 1 MB / 1,048,576 bytes)
- Entries exceeding threshold: store file path/URL only, never load content
- Display file metadata (name, size, type, path) in preview

### FR5: Menu Bar Integration
- NSStatusItem in the macOS menu bar
- Template icon (monochrome, adapts to light/dark menu bar)
- Left-click opens history panel; right-click shows context menu (Settings, Quit)
- No dock icon (LSUIElement = YES)

### FR6: History Panel
- SwiftUI floating panel (NSPanel, non-activating)
- Displays most recent entries (configurable, default: 50)
- Each entry shows: content preview (first 3 lines / thumbnail), timestamp, type badge, source app icon
- Real-time search/filter as user types (no "press Enter" required)
- Scrollable list with lazy loading
- Auto-dismiss on Escape, click-outside, or after paste action

### FR7: Keyboard Navigation
- Global hotkey: ⌘⇧V to toggle panel
- Arrow keys: navigate entries
- Enter: paste selected entry
- Escape: dismiss panel (or clear search if search active)
- ⌘1-9: paste nth entry
- ⌘F: focus search field
- ⌘⌫: delete selected entry
- Tab: cycle between search field and entry list
- Visible focus rings on all interactive elements

### FR8: Paste Integration
- Paste selected entry: write content back to NSPasteboard, then simulate ⌘V
- Support all entry types for paste-back (text, images, file references)
- Option to paste as plain text (strip formatting)

### FR9: Entry Management
- Delete individual entries (with confirmation for pinned)
- Pin/favorite entries (pinned entries never auto-purged)
- Configurable retention period (default: 7 days, options: 1d, 3d, 7d, 30d, forever)
- Auto-purge expired entries on launch and periodically

### FR10: Settings Window
- SwiftUI Settings scene (⌘,)
- Sections: General (retention, threshold, max entries), Security (content filtering stubs), About
- Preferences persisted via UserDefaults with App Group support

## Non-Functional Requirements

### NFR1: Performance
- Panel open latency: <200ms from hotkey press
- Clipboard capture latency: <100ms from pasteboard change
- Search: sub-50ms for up to 10,000 entries
- Idle memory: <50MB

### NFR2: Security (Non-Negotiable)
- Zero network access — no entitlements that enable networking
- All persisted data encrypted at rest (AES-GCM)
- App Sandbox enabled with minimal entitlements
- Encryption key in Keychain (never in UserDefaults or plain files)
- Memory cleared on entry dismissal
- No third-party analytics, telemetry, or crash reporters

### NFR3: Reliability
- Graceful handling of empty clipboard, malformed data, missing files
- Database migration support for schema evolution
- No data loss on crash (WAL mode + proper transaction handling)

### NFR4: Compatibility
- macOS 14.0 (Sonoma) minimum deployment target
- Native Apple Silicon support (arm64); Intel (x86_64) optional
- Dark mode and light mode support (dark-first design)

## Acceptance Criteria

1. Copy text in any app → panel shows entry with preview within 100ms
2. Copy image → panel shows thumbnail preview
3. Copy file in Finder → panel shows file metadata, not file contents
4. Press ⌘⇧V → panel opens in <200ms, keyboard navigation works
5. Search filters entries in real-time with sub-50ms latency
6. Press Enter → selected entry pasted into frontmost app
7. Quit and relaunch → all entries preserved and still searchable
8. Database file on disk is encrypted (verify via hex dump — no plain text)
9. App has zero network entitlements (verify via `codesign -d --entitlements`)
10. Full test suite passes with ≥95% line coverage

## Out of Scope (Deferred)
- iPhone Universal Clipboard handoff detection (Track 2)
- Sensitive content filtering (credit cards, passwords) (Track 3)
- Markdown rendering with syntax highlighting (Track 2)
- Custom icon design (using placeholder SF Symbol)
- iCloud sync
- Export/import history
