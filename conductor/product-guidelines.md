# Product Guidelines

## Brand Voice & Tone

**Minimal & Utilitarian.** The app communicates with brevity and precision. Every label, tooltip, and setting description serves a purpose — no filler, no personality for its own sake.

### Guidelines
- Labels use imperative or noun forms: "Search", "History", "Pinned"
- Status messages are terse: "Copied", "3 entries today"
- Never use exclamation marks or emoji in interface copy
- Error messages state what happened and what to do: "Cannot open file. The path may have changed."
- Preference labels describe the behavior, not the benefit: "Exclude passwords from history" not "Keep your passwords safe!"

## Visual Design System

### Foundation: macOS Native (HIG) with Dark-Mode Forward

The app adheres strictly to Apple's Human Interface Guidelines while being optimized for dark mode as the primary viewing experience.

### Color Palette
- **Primary Background**: NSVisualEffectView with `.menu` material — translucent dark with refined blur and frosted glass effect
- **Accent Color**: System accent color (user-configurable) for selection highlights and active states
- **Syntax Highlighting**: Monokai-inspired palette for code blocks — high contrast against dark backgrounds, optimized for readability
- **Text Hierarchy**: `.primary`, `.secondary`, `.tertiary` label colors from the system color palette
- **Semantic Colors**: System green for success, yellow for warnings, red for destructive actions — always Apple's standard tints

### Typography
- **System Font**: SF Pro (default macOS system font) — no custom typefaces
- **Monospace**: SF Mono for code, file paths, and technical content
- **Size Scale**: Apple's standard dynamic type sizes — `.body`, `.headline`, `.caption`, etc. — respecting user's system-wide text size preference

### Iconography
- **SF Symbols**: Exclusively use Apple's SF Symbols library for all interface icons — consistent with macOS, automatically adapts to weight and scale
- **Menu Bar Icon**: Custom template icon (monochrome, adapts to menu bar appearance)

### Dark Mode Priority
- All assets, colors, and textures designed for dark mode first
- Light mode is fully supported but considered secondary
- Syntax highlighting themes include both dark and light variants

## Naming & Branding

### App Name Direction: Abstract & Professional
- Short, memorable, single-word name
- Suggests security and permanence without being literal
- Examples: "ClipVault", "PasteLock", "ClipSafe"

### Icon Direction
- Clean, geometric design at home in the macOS menu bar
- Lock + clipboard motif merged into a single recognizable silhouette
- Template (monochrome) rendering for menu bar; full color for Finder/About

## Accessibility Standards

### Priority: Keyboard-Only Operation
Every function in the app must be reachable and usable without a mouse.

### Requirements
- **Full Keyboard Navigation**: Tab, arrow keys, Enter, Escape, and Space cover all interactions
- **Global Hotkey**: Single configurable shortcut to show/hide the app (default: ⌘⇧V)
- **Panel Navigation**: Arrow keys browse history; Enter pastes selected entry; Escape dismisses; ⌘F focuses or refocuses search
- **Quick Actions**: ⌘1-9 to paste the nth entry; ⌘P to pin; ⌘⌫ to delete; ⌘C to copy entry to clipboard; ⌘W to close current window or dismiss panel
- **Settings Navigation**: Standard macOS preferences window with tab-based navigation reachable via ⌘,
- **Focus Rings**: Visible focus indicators on all interactive elements for keyboard users

### VoiceOver (Secondary)
- While keyboard-only is the priority, all standard NSView/SwiftUI controls come with basic VoiceOver support by default
- Critical paths (opening panel, browsing history, pasting) should function with VoiceOver
- Full VoiceOver audit deferred to post-MVP

## UX Patterns

### Panel Behavior
- **Floating Panel**: Non-activating NSPanel — doesn't steal focus from the active application
- **Auto-Dismiss**: Closes on Escape, click-outside, or after pasting an entry
- **Position**: Anchored below the menu bar status item; remembers last position
- **Size**: Default width of **420pt**; panel height adjusts to show configurable number of entries
- **Interaction**: Single-click to select; Enter or double-click to copy; Double-click selects the item and opens Detailed View for full inspection.
- **Window Management**: Settings and Detailed View are managed as standard macOS windows (child windows of the panel) to ensure reliable foreground behavior and Z-order enforcement.

### Search
- **Real-Time Filter**: Type to filter history entries immediately — no "press Enter to search"
- **Fuzzy Matching**: Matches against content preview, source app, and date
- **Clear on Escape**: Pressing Escape clears the search query; second Escape dismisses the panel
- **Refocusing**: Pressing ⌘F while the panel is visible returns focus to the search bar.

### Content Preview
- **Text / Code / Markdown / HTML**: Show first 3 lines with ellipsis overflow.
- **Images**: 48px thumbnail with filename overlay. Includes support for cropped image data.
- **Files**: Icon + filename + size + path
- **URLs**: Domain + page title if available

### Detailed Entry View
- **Behavior**: Opened via double-click on a list entry.
- **File Content**: For `.file` types representing folders or multiple selections, the detailed view lists the contained file names instead of just the path.
- **PDF Preview**: Provides a full scrollable and zoomable interface using native PDFKit.
