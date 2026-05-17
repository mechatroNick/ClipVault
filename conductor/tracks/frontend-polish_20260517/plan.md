# Implementation Plan: Frontend Polish & Accessibility

## Phase 1: Lifecycle & UI Accessibility

- [ ] Task: Implement right-click context menu for status item
    - [ ] Update `MenuBarController` to handle right-click events.
    - [ ] Add `Settings...` and `Quit` items to the context menu.
    - [ ] Commit: `feat(ui): Add right-click context menu to status bar icon`

- [ ] Task: Add inline Panel controls
    - [ ] Update `HistoryPanelView` header to include Gear (Settings) and Close (X) buttons.
    - [ ] Implement `closePanel` action.
    - [ ] Commit: `feat(ui): Add inline Settings and Close buttons to history panel`

- [ ] Task: Implement 'Launch at Login'
    - [ ] Integrate `LaunchAtLogin` helper or use `SMAppService`.
    - [ ] Add logic to enable login item by default on first launch.
    - [ ] Commit: `feat(lifecycle): Implement Launch at Login functionality`

- [ ] Task: Enhanced Metadata Capture (Local)
    - [ ] Update `ClipboardCaptureService` to use `NSWorkspace` for active window title.
    - [ ] Update `ClipboardEntry` model to store `windowTitle`.
    - [ ] Commit: `feat(clipboard): Capture active window title during copy`

- [ ] Task: Implement On-Demand Decryption Architecture
    - [ ] Update `ClipboardEntry` with `windowTitle` and `deviceName` string columns.
    - [ ] Add migration to add these columns to the database.
    - [ ] Refactor `ClipboardRepository.observeEntries` to remove bulk decryption.
    - [ ] Implement `ClipboardRepository.decryptContent(for:)` for lazy loading.
    - [ ] Update `ClipboardCaptureService` to populate new plaintext columns.
    - [ ] Commit: `refactor(storage): Implement on-demand decryption and plaintext metadata`

- [ ] Task: Conductor - User Manual Verification 'Phase 1' (Protocol in workflow.md)

## Phase 2: Resizability, Scaling & Persistence

- [ ] Task: Enable resizable NSPanel
    - [ ] Add `.resizable` to `HistoryPanel` style mask.
    - [ ] Ensure SwiftUI content correctly adapts to window resizing.
    - [ ] Commit: `feat(ui): Enable history panel resizability`

- [ ] Task: Implement size and position persistence
    - [ ] Add `panelFrame` and `zoomLevel` to `SettingsManager`.
    - [ ] Update `MenuBarController` to save/restore frame on open/close/resize.
    - [ ] Implement Keyboard Zoom (⌘+/⌘-).
    - [ ] Commit: `feat(ui): Persist panel frame and implement UI zoom`

- [ ] Task: Conductor - User Manual Verification 'Phase 2' (Protocol in workflow.md)

## Phase 3: Interactive Previews & Controls

- [ ] Task: Implement Hover Previews
    - [ ] Add hover state tracking to `EntryRowView`.
    - [ ] Implement enlarged overlay preview using `ContentPreviewRouter`.
    - [ ] Commit: `feat(ui): Add interactive hover previews for entries`

- [ ] Task: Add 'Copy' button with file validation
    - [ ] Add 'Copy' button to each entry row.
    - [ ] Implement file existence check for file/folder references.
    - [ ] Show warning badge if file is missing.
    - [ ] Commit: `feat(ui): Add per-item copy with file existence validation`

- [ ] Task: UI Integration for Granular Metadata
    - [ ] Update `EntryRowView` to display: window title, formatted timestamp, and device origin icon.
    - [ ] Add "Local Mac" vs "iPhone/iPad" labels based on `isRemote` flag.
    - [ ] Commit: `feat(ui): Display granular metadata in history entries`

- [ ] Task: Implement Rich Content Rendering (Markdown & HTML)
    - [ ] Enhance `MarkdownRenderer` to support block-level styles.
    - [ ] Implement `RichTextRenderer` for RTF and HTML data using `NSAttributedString`.
    - [ ] Update `ContentPreviewRouter` to route "rtf" and "html" types to a new `RichTextPreview` component.
    - [ ] Commit: `feat(ui): Add HTML and RTF rendering to history panel`

- [ ] Task: Conductor - User Manual Verification 'Phase 3' (Protocol in workflow.md)

## Phase 4: Sensitive Expiry & Advanced Settings

- [ ] Task: Implement sensitive item auto-expiry
    - [ ] Update `ClipboardRepository` to assign default expiry (1h) to sensitive items.
    - [ ] Implement background purge task in `ClipboardCaptureService`.
    - [ ] Commit: `feat(security): Implement auto-expiry for sensitive entries`

- [ ] Task: Implement storage auto-trimming
    - [ ] Add `VaultSizeMonitor` service or background task to calculate total storage usage.
    - [ ] Implement trimming logic: sort vaulted files by age and delete until total size is below limit.
    - [ ] Commit: `feat(storage): Implement background vault size monitoring and auto-trimming`

- [ ] Task: Finalize Settings UI with 'Save' button
    - [ ] Add configuration for "Sensitive Purge Time", "Storage Limit", and "Launch at Login".
    - [ ] Add a prominent "Save" button to the Settings window.
    - [ ] Ensure "Save" triggers immediate persistence and application of all settings.
    - [ ] Commit: `feat(ui): Finalize settings UI with Save button and advanced controls`

- [ ] Task: Conductor - User Manual Verification 'Phase 4' (Protocol in workflow.md)

## Phase 5: Search & Performance Optimization

- [ ] Task: Implement Debounced Search
    - [ ] Add debounce logic (300ms) to the search query binding in `ClipboardViewModel`.
    - [ ] Ensure database queries only trigger after the user stops typing.
    - [ ] Commit: `perf(ui): Implement debounced search for history panel`

- [ ] Task: Implement Pagination & Lazy Loading
    - [ ] Update `ClipboardRepository` to support paginated fetches.
    - [ ] Refactor history list to load additional items as the user scrolls.
    - [ ] Commit: `perf(storage): Add paginated history loading`

- [ ] Task: Implement In-Memory Thumbnail Cache
    - [ ] Add `ThumbnailCache` utility using `NSCache`.
    - [ ] Integrate cache into `EntryRowView` to avoid repeated re-decryption of images.
    - [ ] Commit: `perf(ui): Add in-memory thumbnail caching for smooth scrolling`

- [ ] Task: FTS5 Optimization & Tuning
    - [ ] Audit SQLite search performance with large datasets.
    - [ ] Implement porter tokenizers or prefix indexing if necessary.
    - [ ] Commit: `perf(storage): Optimize FTS5 search index`

- [ ] Task: Conductor - User Manual Verification 'Phase 5' (Protocol in workflow.md)

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
