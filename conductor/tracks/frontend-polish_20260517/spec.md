# Specification: Frontend Polish & Accessibility

## Track ID
`frontend-polish_20260517`

## Overview
Address UI accessibility issues, implement enhanced visualization (resize, zoom, hover), and introduce granular controls with sensitive data auto-expiration, file existence validation, and deep performance optimizations for large history sets.

## Functional Requirements

### FR1: Lifecycle & Accessibility Controls
- **Status Menu**: Add "Settings..." and "Quit" items to a right-click context menu on the status bar icon.
- **Panel Controls**: Add a "Gear" icon (Settings) and a "Close" (X) button to the history panel UI.
- **Quit Integration**: Ensure "Quit" correctly terminates the app and background services.

### FR2: Panel Resizability & Persistence
- **Resizable Window**: Enable the history panel to be resized by the user (NSPanel resize support).
- **Persistence**: Persist the panel's last used size and screen position in user preferences.
- **Zooming**: Implement UI scaling (Zoom In/Out) via keyboard shortcuts (⌘+ / ⌘-).

### FR3: Interactive Hover Previews
- **Enlarged Preview**: Display an enlarged overlay preview when the mouse hovers over a clipboard entry.
- **Smooth Transitions**: Ensure the preview appears and disappears gracefully.

### FR4: Granular Entry Controls
- **Copy Button**: Add a dedicated **Copy** button to each entry row (next to Pin/Delete).
- **Existence Check**: Before re-copying a file/folder reference, verify the path still exists on disk.
- **Warnings**: Display a non-blocking alert/badge if a file reference is broken.

### FR5: Sensitive Data Auto-Expiration
- **Auto-Expiry**: Items flagged as "Sensitive" default to a configurable auto-purge time (default 1h).
- **Configurable Settings**: Add "Sensitive Purge Time" and "Large File Threshold" to the Settings UI.
- **UI Indicators**: Show an expiry label or icon for sensitive items.

### FR6: Storage Management & Auto-Trimming
- **Storage Limit**: Enforce a default storage limit of 10GB for the Vault folder.
- **Auto-Trimming**: Implement a background process that monitors Vault size. If the limit is exceeded, automatically purge the oldest vaulted files (FIFO).

### FR7: Comprehensive Settings UI
- **Configurable Settings List**:
    - **General**: Launch at Login (default: true), History Retention, Max Entries, UI Zoom Level.
    - **Vault**: Vault Location, Large File Threshold, Storage Limit (GB), Auto-trim toggle.
    - **Security**: Sensitive Purge Time (hours), Custom Redaction Rules (Regex).
- **Save Action**: Include a prominent "Save" button in the Settings window that forces an immediate write/application of all changed values.
- **Launch at Startup**: Implement startup item registration to handle the "Launch at Login" functionality.

### FR8: Granular Metadata Display
- **Enhanced Window Tracking**: Capture the specific window title of the active application at the time of copy (e.g., the browser tab name, the MS Word document name, or the VSCode filename).
- **Explicit Device Labeling**: Clearly display the device of origin. Use labels like "This Mac", "iPhone", or "iPad" alongside an appropriate icon.
- **Detailed Timestamps**: Display the exact time of copy in a user-friendly format (e.g., "Today at 2:45 PM" or relative "5m ago").
- **UI Integration**: Incorporate this metadata into the `EntryRowView`.

### FR9: Rich Content Rendering & Preview
- **Enhanced Markdown**: Improve `MarkdownRenderer` to handle block-level elements (lists, headers) more reliably.
- **HTML/RTF Support**: Implement a `RichTextRenderer` that converts captured RTF/HTML data into `AttributedString` for native SwiftUI display.
- **Styling Preservation**: Preserve basic formatting (bold, italic, color) while ensuring the text scales correctly with the UI Zoom Level.

### FR10: On-Demand Decryption Architecture
- **Plaintext Metadata**: Store all UI-visible attributes in plaintext database columns (Timestamp, App Name, Window Title, Device Name, Content Type, isPinned, isRemote).
- **Encrypted Content Blobs**: Keep only the actual "payload" (plain text, rich text, image data) encrypted with AES-256-GCM.
- **Deferred Decryption**: Content should only be decrypted when strictly needed (hover/select/paste).
- **Performance**: Render the history list without Keychain access or cryptographic overhead.

### FR11: Search & List Optimization
- **Debounced Search**: Keystrokes in the search bar must be debounced (e.g., 300ms delay) to prevent redundant database queries during rapid typing.
- **Lazy Loading & Pagination**: Use lazy loading (`LazyVStack` or `List`) and implement paginated database fetches for large result sets.
- **Thumbnail Cache**: Cache decrypted thumbnails in memory (`NSCache`) to ensure smooth scrolling.
- **FTS5 Tuning**: Optimize the search index for sub-50ms performance across 10,000+ entries.

## Acceptance Criteria
1. Right-clicking the status icon shows a functional menu with Settings and Quit.
2. The history panel has visible and working Settings and Close buttons.
3. Resizing and zooming persist across app restarts.
4. Hovering over an entry shows an enlarged preview.
5. Copying a non-existent file triggers a user warning.
6. Sensitive items are automatically purged after the configured time.
7. Vault storage size is monitored; background trimming successfully removes old files when the limit is reached.
8. Settings UI allows configuring all values in the consolidated settings list.
9. "Launch at Login" setting works and defaults to enabled.
10. Clicking "Save" in the Settings window immediately applies and persists all changes.
11. Every clipboard entry displays: App Name, Window/Document Title, Timestamp, and Device Origin.
12. HTML and RTF items are rendered with preserved styling in the preview.
13. Search results update with a 300ms debounce.
14. Scrolling through 1,000 entries remains smooth at 60fps.
15. History list renders instantly without Keychain access.
