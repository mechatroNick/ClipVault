# Specification: UI Fixes & Markdown Rendering

## Track ID
`ui-fixes-markdown_20260520`

## Overview
Address user-reported UI bugs and implement new visualization features. This track focuses on fixing Markdown/HTML rendering logic, ensuring proper multi-line text previews, making the Settings button functional, preventing text clipping, safely auto-creating the Vault directory, adding build info, and introducing a new detailed view on double-click.

## Requirements

### 1. Markdown & HTML Rendering Fixes
- **Strict Validation**: Before attempting to render Markdown or HTML in the `HistoryPanelView` (specifically on hover or in detailed views), strictly validate that the content is syntactically valid (no broken tags, unclosed blocks, etc.).
- **Graceful Degradation**: If validation fails or rendering throws an error, gracefully fall back to displaying the raw plain text.
- **Hover Previews**: Ensure hover previews (Markdown, HTML, Image) are displayed correctly without breaking layout.

### 2. List View Content Previews
- **Multi-line Text Preview**: `EntryRowView` must display up to 3 lines of text for `.text`, `.markdown`, `.code`, and `.html` types before truncating with an ellipsis (`...`).
- **Image Thumbnails**: Ensure `.image` types display a proper image thumbnail.

### 3. Detailed Entry View (Double-Click)
- **Interaction**: Double-clicking an entry in the history list must open a separate, larger "Detailed View" window or popover to view the item in its entirety.
- **Content Rendering**:
    - **Text/Markdown/Code/HTML**: Show the full content (rendered appropriately based on type).
    - **Images**: Show the full-size image.
    - **Files/Folders**: Instead of just the path, enumerate and display a list of the files contained within the copied selection.

### 4. UI & Navigation Fixes
- **Settings View**: Fix the interaction where clicking the Settings (Gear) icon in the menu bar panel fails to open the `SettingsView`. Ensure the window anchors or opens correctly in the foreground.
- **Text Clipping**: Audit `EntryRowView` and `HistoryPanelView` to fix instances where text is clipped abruptly (e.g., cutting off the bottom of letters) using proper layout constraints.

### 5. Vault Directory Management
- **Auto-Creation**: Check if the Vault Root Path (default: `~/Documents/VaultClip`) exists on launch.
- **Safe Initialization**: Create the directory if it does not exist. 
- **Non-Destructive**: Ensure creation logic never deletes/overwrites existing content.

### 6. About View Enhancements
- **Build Time Display**: Update the About tab to display the exact build time alongside the release version number.

## Acceptance Criteria
1. **Markdown/HTML**: Broken syntax falls back to plain text; valid syntax renders correctly.
2. **List Previews**: Text-based entries show up to 3 lines of preview text; images show thumbnails.
3. **Detailed View**: Double-clicking an entry opens a full view; file/folder entries list their contents.
4. **Settings**: Clicking the Gear icon reliably opens the Settings window.
5. **UI Layout**: Long text wraps or truncates neatly without vertical clipping.
6. **Vault Init**: The `~/Documents/VaultClip` directory is safely auto-created on first run.
7. **Build Info**: The About view displays the build time.
8. **Tests**: All new edge cases are covered by unit tests.
