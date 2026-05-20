# ClipVault User Guide

Welcome to ClipVault! ClipVault is a secure, native macOS clipboard manager designed to live in your menu bar and keep your history safe.

## Getting Started

### Installation
1. Move `ClipVault.app` to your `/Applications` folder.
2. Launch the application. You will see a new clipboard icon appear in your macOS menu bar at the top right of your screen.

### First Run & Permissions
By default, ClipVault operates entirely within a secure App Sandbox and does not require any special permissions to monitor and save your clipboard history. 

**Optional Auto-Paste Feature:**
If you want ClipVault to automatically paste an item into your current application when you select it, you must enable this feature.
1. Click the ClipVault menu bar icon to open the panel.
2. Click the **Gear icon** (Settings) in the top left.
3. Check the box for **"Enable Auto-Paste (Requires Accessibility Permission)"**.
4. macOS will prompt you to grant Accessibility permissions to ClipVault in System Settings > Privacy & Security.

## Using ClipVault

### Viewing History
- Click the clipboard icon in your menu bar, or use the global keyboard shortcut (default: **⌘⇧V**), to open the history panel.
- Your clipboard history is displayed in a scrolling list. ClipVault supports rich previews for:
  - **Text & Links**: Plain text, URLs.
  - **Code**: Syntax-highlighted snippets.
  - **Markdown**: Fully rendered inline previews.
  - **Images**: Automatically generated thumbnails.
  - **Files**: File icons and paths.

### Searching
- When the panel is open, simply start typing to search your history.
- The search is instantaneous and accent-insensitive.
- **Note:** For security, sensitive items (like detected credit card numbers) are redacted in the search index and cannot be found via search queries, though they remain visible in the main list.

### Managing Entries
Hover over any entry in the list to reveal quick actions:
- **Copy (doc icon)**: Copies the item back to your system clipboard (and pastes it if Auto-Paste is enabled).
- **Pin (pin icon)**: Pins the item to the top of your history so it is never automatically deleted.
- **Delete (trash icon)**: Permanently deletes the item.

### Keyboard Shortcuts
You can navigate the entire panel without using your mouse:
- **↑ / ↓ Arrows**: Navigate the history list.
- **Enter / Return**: Copy (and paste) the selected item.
- **⌘1 through ⌘9**: Quickly copy/paste the first through ninth items in the list.
- **⌘P**: Pin or unpin the selected item.
- **⌘⌫ (Command + Delete)**: Delete the selected item.
- **⌘C**: Copy the selected item.
- **Escape**: Close the panel.

## Security & Privacy Settings

ClipVault is designed with your privacy in mind. Access these options via the **Gear icon**:

- **Retention (Days)**: How long standard clipboard entries are kept before being automatically deleted. (Default: 7 days).
- **Sensitive Purge Time (Hours)**: ClipVault automatically detects potentially sensitive strings (like credit cards or secrets). This setting determines how quickly those specific items are aggressively purged from your history. (Default: 1 hour).
- **Storage Limit (MB)**: A safety limit to prevent the database from taking up too much disk space. Large files (like big images or copied files) are stored in a separate secure vault on disk to keep the main database fast.

All clipboard data is encrypted on your hard drive using AES-256-GCM and a key stored safely in your Mac's Keychain.
