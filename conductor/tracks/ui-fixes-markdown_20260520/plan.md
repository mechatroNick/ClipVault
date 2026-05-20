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

- [x] Task: Conductor - User Manual Verification 'Phase 2' (Protocol in workflow.md)

## Phase 3: Markdown Validation & Error Handling

- [x] Task: Strict Markdown and HTML Validation
    - [x] Implement validation logic in `MarkdownRenderer` and/or `ContentTypeDetector` to verify syntax before rendering.
    - [x] Update `RichTextRenderer` to handle rendering errors gracefully and return nil.
    - [x] Update `ContentPreviewRouter` to fall back to `TextPreview` if rendering fails.
    - [x] Write unit tests for valid and invalid Markdown/HTML scenarios.
    - [x] Commit: `fix(ui): Implement strict markdown validation and graceful fallback`

- [x] Task: Conductor - User Manual Verification 'Phase 3' (Protocol in workflow.md)

## Phase 4: UI Polish & Settings

- [x] Task: Fix Settings and Quit Button Interaction
    - [x] Debug and fix the interaction issue where clicking the Settings (Gear) icon or the Quit button fails to respond.
    - [x] Adjust the layout and size of the Settings and Quit buttons to ensure they are accessible and not too close to the search bar.
    - [x] Ensure `SettingsView` is brought to the foreground correctly when the Settings button is clicked.
    - [x] Ensure the app terminates cleanly when the Quit button is clicked.
    - [x] Commit: `fix(ui): Polish Settings/Quit buttons layout and functionality`

- [x] Task: Prevent Duplication when Copying from History
    - [x] Update `ClipboardCaptureService` or `PasteboardMonitor` to ignore captures originating from ClipVault's own copy action.
    - [x] Add an "Active Clipboard" marker in the UI for the currently active item instead of duplicating it.
    - [x] Commit: `fix(clipboard): Prevent duplication when copying from history and add active marker`

- [x] Task: Resolve Text Clipping Issues
    - [x] Audit `EntryRowView` padding and frame constraints.
    - [x] Ensure font leading and line spacing do not cause descender clipping.
    - [x] Commit: `fix(ui): Resolve vertical text clipping in list view`

- [x] Task: Display Build Time in About View
    - [x] Add a build phase script or macro to inject the build timestamp into Info.plist or a generated Swift file.
    - [x] Update `AboutSettingsView` to display this timestamp.
    - [x] Commit: `feat(ui): Display build time in About view`

- [ ] Task: Conductor - User Manual Verification 'Phase 4' (Protocol in workflow.md)
