# Implementation Plan: UI Fixes & Markdown Rendering

## Phase 1: Vault Management & Infrastructure

- [x] Task: Implement Safe Vault Directory Auto-Creation
    - [x] Update `VaultManager` initialization to check for the existence of the root path.
    - [x] Implement safe creation logic using `FileManager` that does not overwrite existing data.
    - [x] Write unit tests verifying creation and non-destructive behavior.
    - [x] Commit: `fix(storage): Safely auto-create Vault directory on launch`

- [x] Task: Conductor - User Manual Verification 'Phase 1' (Protocol in workflow.md)

## Phase 2: Content Previews & Detailed View

- [x] Task: Multi-line Text Previews in List View
    - [x] Update `ContentPreviewRouter` and `TextPreview` to ensure a maximum of 3 lines are shown.
    - [x] Apply appropriate truncation (`.truncationMode(.tail)`) and line limits.
    - [x] Commit: `feat(ui): Enable multi-line text previews in history list`

- [x] Task: Implement Detailed Entry View
    - [x] Create a new SwiftUI View `DetailedEntryView` to display full content.
    - [x] Add logic in `DetailedEntryView` to list file contents for `.file` types.
    - [x] Update `EntryRowView` to handle double-click (`onTapGesture(count: 2)`) to open the detailed view (via a popover or new window).
    - [x] Write UI/Integration tests for double-click interaction and detailed view rendering.
    - [x] Commit: `feat(ui): Implement detailed entry view on double-click`

- [ ] Task: Conductor - User Manual Verification 'Phase 2' (Protocol in workflow.md)

## Phase 3: Markdown Validation & Error Handling

- [ ] Task: Strict Markdown and HTML Validation
    - [ ] Implement validation logic in `MarkdownRenderer` and/or `ContentTypeDetector` to verify syntax before rendering.
    - [ ] Update `RichTextRenderer` to handle rendering errors gracefully and return nil.
    - [ ] Update `ContentPreviewRouter` to fall back to `TextPreview` if rendering fails.
    - [ ] Write unit tests for valid and invalid Markdown/HTML scenarios.
    - [ ] Commit: `fix(ui): Implement strict markdown validation and graceful fallback`

- [ ] Task: Conductor - User Manual Verification 'Phase 3' (Protocol in workflow.md)

## Phase 4: UI Polish & Settings

- [ ] Task: Fix Settings Button Interaction
    - [ ] Debug and fix the routing/action associated with the Gear icon in `HistoryPanelView`.
    - [ ] Ensure `SettingsView` is brought to the foreground correctly.
    - [ ] Commit: `fix(ui): Restore functionality of Settings button`

- [ ] Task: Resolve Text Clipping Issues
    - [ ] Audit `EntryRowView` padding and frame constraints.
    - [ ] Ensure font leading and line spacing do not cause descender clipping.
    - [ ] Commit: `fix(ui): Resolve vertical text clipping in list view`

- [ ] Task: Display Build Time in About View
    - [ ] Add a build phase script or macro to inject the build timestamp into Info.plist or a generated Swift file.
    - [ ] Update `AboutSettingsView` to display this timestamp.
    - [ ] Commit: `feat(ui): Display build time in About view`

- [ ] Task: Conductor - User Manual Verification 'Phase 4' (Protocol in workflow.md)
imestamp.
    - [ ] Commit: `feat(ui): Display build time in About view`

- [ ] Task: Conductor - User Manual Verification 'Phase 4' (Protocol in workflow.md)
