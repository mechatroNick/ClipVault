# Specification: App Polish & New Features

## Overview
This track implements a suite of design refinements and highly requested features to elevate ClipVault into a more premium and powerful utility. The focus is on a native macOS Settings overhaul, improved visual indicators, enhanced privacy controls, and power-user features.

## Functional Requirements
1. **Settings Window Overhaul**: Replace the current single-view settings with a standard macOS `TabView` window, categorized into tabs (e.g., General, Appearance, Security).
2. **Visual Content Indicators**: Add distinct, tiny icons in the history list to indicate the content type of each entry (Code Snippets `</>`, Plain Text `T`, Images, Files/PDFs).
3. **Customizable Global Hotkey**: Allow users to define their own global shortcut to open ClipVault, replacing the hardcoded `Cmd+Shift+V` default, configurable via the new Settings window.
4. **Privacy Ignore List**: Introduce a user-configurable "Ignore List" in Settings. ClipVault will actively reject clipboard changes originating from these apps. 
    - Default ignore list: `1Password`, `Keychain Access`, `Bitwarden`.
5. **Filter by Pinned/Favorites**: Add a toggle next to the search bar to filter the history view to show only pinned items.
6. **Paste as Plain Text Button**: Introduce a dedicated "Paste as Plain Text" action button. It will be always visible next to the standard Copy button on each entry row.

## Non-Functional Requirements & Design Polish
1. **Empty State Delight**: Replace the static "No history yet" text with a high-quality illustration or fluid animation when the vault is empty.
2. **Entry Insertion Animation**: Implement a smooth slide-down and fade-in animation for new clipboard entries when the panel is actively open, removing the jarring instant snap.

## Out of Scope
- iCloud sync of clipboard history across devices (we still rely on Apple's Universal Clipboard for instantaneous handoff).
