# Specification: Frontend Polish & Accessibility

## Track ID
`frontend-polish_20260517`

## Overview
Address UI accessibility issues, implement enhanced visualization (resize, zoom, hover), and introduce granular controls with sensitive data auto-expiration and file existence validation.

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
- **Auto-Trimming**: Implement a background process that monitors Vault size. If the limit is exceeded, automatically purge the oldest vaulted files (FIFO) until storage is within limits.
- **Configurability**: Add "Storage Limit (GB)" to the Settings UI, allowing users to adjust or disable the limit.

## Acceptance Criteria
...
6. Sensitive items are automatically purged after the configured time.
7. Vault storage size is monitored; background trimming successfully removes old files when the 10GB limit (or user-defined limit) is reached.
8. Settings UI allows configuring the storage limit.
