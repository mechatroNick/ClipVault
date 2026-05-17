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
