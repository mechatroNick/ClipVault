# Implementation Plan: App Polish & New Features

## Phase 1: UI Polish & Animations
- [x] Task: Visual Content Indicators
    - [x] Write unit tests for content type identification logic
    - [x] Implement distinct icons for Code Snippets, Plain Text, Images, and Files in `EntryRowView`
    - [x] Run test suite, verify ≥95% coverage
- [x] Task: Empty State Delight
    - [x] Write UI tests for empty state presentation
    - [x] Implement custom illustration or animation for the empty state in `HistoryPanelView`
    - [x] Run test suite, verify ≥95% coverage
- [x] Task: Entry Insertion Animation
    - [x] Implement smooth slide-down and fade-in animation for new clipboard entries in `HistoryPanelView`
    - [x] Run test suite, verify ≥95% coverage
- [x] Task: Conductor - User Manual Verification 'UI Polish & Animations' (Protocol in workflow.md)

## Phase 2: Core Features
- [x] Task: Paste as Plain Text Button
    - [x] Write unit tests for plain text extraction and pasting logic
    - [x] Implement dedicated "Paste as Plain Text" button in `EntryRowView` next to the standard Copy button
    - [x] Run test suite, verify ≥95% coverage
- [x] Task: Filter by Pinned/Favorites
    - [x] Write unit tests for pinned filtering logic in `ClipboardViewModel`
    - [x] Implement filter toggle next to the search bar in `HistoryPanelView`
    - [x] Run test suite, verify ≥95% coverage
- [x] Task: Conductor - User Manual Verification 'Core Features' (Protocol in workflow.md)

## Phase 3: Settings & Privacy Overhaul
- [x] Task: Settings Window Overhaul
    - [x] Write UI tests for `TabView` navigation
    - [x] Implement standard macOS `TabView` window for Settings (General, Appearance, Security)
    - [x] Run test suite, verify ≥95% coverage
- [x] Task: Customizable Global Hotkey
    - [x] Write unit tests for hotkey registration and persistence
    - [x] Implement global hotkey recording UI in Settings and integrate with `MenuBarController`
    - [x] Run test suite, verify ≥95% coverage
- [x] Task: Privacy Ignore List
    - [x] Write unit tests for ignore list matching and clipboard filtering
    - [x] Implement "Ignore List" UI in Settings (defaulting to 1Password, Keychain Access, Bitwarden)
    - [x] Implement clipboard change rejection logic in `ClipboardMonitor`
    - [x] Run test suite, verify ≥95% coverage
    - [x] Run security review checklist
- [ ] Task: Conductor - User Manual Verification 'Settings & Privacy Overhaul' (Protocol in workflow.md)
