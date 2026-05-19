# Implementation Plan: Frontend Polish & Accessibility

## Phase 1: Lifecycle & UI Accessibility

- [x] Task: Implement right-click context menu for status item
    - [x] Update `MenuBarController` to handle right-click events.
    - [x] Add `Settings...` and `Quit` items to the context menu.
    - [x] Commit: `feat(ui): Add right-click context menu to status bar icon`

- [x] Task: Add inline Panel controls
    - [x] Update `HistoryPanelView` header to include Gear (Settings) and Close (X) buttons.
    - [x] Implement `closePanel` action.
    - [x] Commit: `feat(ui): Add inline Settings and Close buttons to history panel`

- [x] Task: Implement 'Launch at Login'
    - [x] Integrate `LaunchAtLogin` helper or use `SMAppService`.
    - [x] Add logic to enable login item by default on first launch.
    - [x] Commit: `feat(lifecycle): Implement Launch at Login functionality`

- [x] Task: Enhanced Metadata Capture (Local)
    - [x] Update `ClipboardCaptureService` to use `NSWorkspace` for active window title.
    - [x] Update `ClipboardEntry` model to store `windowTitle`.
    - [x] Commit: `feat(clipboard): Capture active window title during copy`

- [x] Task: Implement On-Demand Decryption Architecture
    - [x] Update `ClipboardEntry` with `windowTitle` and `deviceName` string columns.
    - [x] Add migration to add these columns to the database.
    - [x] Refactor `ClipboardRepository.observeEntries` to remove bulk decryption.
    - [x] Implement `ClipboardRepository.decryptContent(for:)` for lazy loading.
    - [x] Update `ClipboardCaptureService` to populate new plaintext columns.
    - [x] Commit: `refactor(storage): Implement on-demand decryption and plaintext metadata`

- [x] Task: Implement Smart Consecutive Deduplication
    - [x] Integrate a quick hashing utility (e.g., SHA-256 via CryptoKit).
    - [x] Update `ClipboardCaptureService` to hash new content and compare against the latest history entry.
    - [x] Skip storage if both the content hash and source application are identical.
    - [x] Commit: `feat(clipboard): Add consecutive deduplication with efficient hashing`

- [x] Task: Conductor - User Manual Verification 'Phase 1' (Protocol in workflow.md)

## Phase 2: Resizability, Scaling & Persistence

- [x] Task: Enable resizable NSPanel
    - [x] Add `.resizable` to `HistoryPanel` style mask.
    - [x] Ensure SwiftUI content correctly adapts to window resizing.
    - [x] Commit: `feat(ui): Enable history panel resizability`

- [x] Task: Implement size and position persistence
    - [x] Add `panelFrame` and `zoomLevel` to `SettingsManager`.
    - [x] Update `MenuBarController` to save/restore frame on open/close/resize.
    - [x] Implement Keyboard Zoom (⌘+/⌘-).
    - [x] Commit: `feat(ui): Persist panel frame and implement UI zoom`

- [x] Task: Conductor - User Manual Verification 'Phase 2' (Protocol in workflow.md)

## Phase 3: Interactive Previews & Controls

- [x] Task: Implement Hover Previews
    - [x] Add hover state tracking to `EntryRowView`.
    - [x] Implement enlarged overlay preview using `ContentPreviewRouter`.
    - [x] Commit: `feat(ui): Add interactive hover previews for entries`

- [x] Task: Add 'Copy' button with file validation
    - [x] Add 'Copy' button to each entry row.
    - [x] Implement file existence check for file/folder references.
    - [x] Show warning badge if file is missing.
    - [x] Commit: `feat(ui): Add per-item copy with file existence validation`

- [x] Task: UI Integration for Granular Metadata
    - [x] Update `EntryRowView` to display: window title, formatted timestamp, and device origin icon.
    - [x] Add "Local Mac" vs "iPhone/iPad" labels based on `isRemote` flag.
    - [x] Commit: `feat(ui): Display granular metadata in history entries`

- [x] Task: Implement Rich Content Rendering (Markdown & HTML)
    - [x] Enhance `MarkdownRenderer` to support block-level styles.
    - [x] Implement `RichTextRenderer` for RTF and HTML data using `NSAttributedString`.
    - [x] Update `ContentPreviewRouter` to route "rtf" and "html" types to a new `RichTextPreview` component.
    - [x] Commit: `feat(ui): Add HTML and RTF rendering to history panel`

- [x] Task: Conductor - User Manual Verification 'Phase 3' (Protocol in workflow.md)

## Phase 4: Sensitive Expiry & Advanced Settings

- [x] Task: Implement sensitive item auto-expiry
    - [x] Update `ClipboardRepository` to assign default expiry (1h) to sensitive items.
    - [x] Implement background purge task in `ClipboardCaptureService`.
    - [x] Commit: `feat(security): Implement auto-expiry for sensitive entries`

- [x] Task: Implement storage auto-trimming
    - [x] Add `VaultSizeMonitor` service or background task to calculate total storage usage.
    - [x] Implement trimming logic: sort vaulted files by age and delete until total size is below limit.
    - [x] Commit: `feat(storage): Implement background vault size monitoring and auto-trimming`

- [x] Task: Finalize Settings UI with 'Save' button
    - [x] Add configuration for "Sensitive Purge Time", "Storage Limit", and "Launch at Login".
    - [x] Add a prominent "Save" button to the Settings window.
    - [x] Ensure "Save" triggers immediate persistence and application of all settings.
    - [x] Commit: `feat(ui): Finalize settings UI with Save button and advanced controls`

- [x] Task: Conductor - User Manual Verification 'Phase 4' (Protocol in workflow.md)

## Phase 5: Search & Performance Optimization

- [x] Task: Implement Debounced Search
    - [x] Add debounce logic (300ms) to the search query binding in `ClipboardViewModel`.
    - [x] Ensure database queries only trigger after the user stops typing.
    - [x] Commit: `perf(ui): Implement debounced search for history panel`

- [x] Task: Implement Pagination & Lazy Loading
    - [x] Update `ClipboardRepository` to support paginated fetches.
    - [x] Refactor history list to load additional items as the user scrolls.
    - [x] Commit: `perf(storage): Add paginated history loading`

- [x] Task: Implement In-Memory Thumbnail Cache
    - [x] Add `ThumbnailCache` utility using `NSCache`.
    - [x] Integrate cache into `EntryRowView` to avoid repeated re-decryption of images.
    - [x] Commit: `perf(ui): Add in-memory thumbnail caching for smooth scrolling`

- [x] Task: FTS5 Optimization & Tuning
    - [x] Audit SQLite search performance with large datasets.
    - [x] Implement prefix indexing and standardized tokenizer.
    - [x] Commit: `perf(storage): Optimize FTS5 search index`

- [x] Task: Make Accessibility Privileges Optional
    - [x] Add `simulatePasteEnabled` toggle in `SettingsManager`.
    - [x] Update `PasteService` to gate HID event simulation behind this setting.
    - [x] Commit: `feat(security): Make high-privilege automated pasting optional`

- [x] Task: Conductor - User Manual Verification 'Phase 5' (Protocol in workflow.md)

## Phase 6: Visual Delight & Eye Candy

- [ ] Task: Implement Fluid UI Animations
    - [ ] Add slide-down/fade-in transitions for the history panel.
    - [ ] Implement spring animations for entry removal.
    - [ ] Commit: `feat(ui): Add fluid animations for panel and list items`

- [ ] Task: Enhance Button Feedback & Haptics
    - [ ] Implement hover scaling for row action icons.
    - [ ] Integrate `NSHapticFeedbackManager` for copy/paste actions.
    - [ ] Add temporary "Copied!" checkmark feedback.
    - [ ] Commit: `feat(ui): Add hover effects and haptic feedback`

- [ ] Task: Apply macOS Aesthetic Polish
    - [ ] Implement `NSVisualEffectView` background for the frosted glass effect.
    - [ ] Refine borders, shadows, and spacing for a premium native look.
    - [ ] Commit: `feat(ui): Apply final aesthetic polish and frosted glass effect`

- [ ] Task: Conductor - User Manual Verification 'Phase 6' (Protocol in workflow.md)
