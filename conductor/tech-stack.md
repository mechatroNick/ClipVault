# Technology Stack

## Language

**Swift 5.10+** — Apple's modern, type-safe programming language. Full access to all macOS APIs, Swift Concurrency (async/await), and Swift Macros for code generation.

### Rationale
- Native performance with automatic memory management (ARC)
- First-class support for all Apple frameworks (AppKit, SwiftUI, CryptoKit, Combine, PDFKit)
- Strong type safety reduces entire categories of bugs
- Swift Concurrency simplifies clipboard monitoring and background tasks

## UI Framework

**SwiftUI** — Apple's declarative UI framework. The entire interface (history panel, settings, menus) is built with SwiftUI, leveraging its reactive data flow for real-time clipboard updates.

### Key SwiftUI Features Used
- `@Observable` (Swift 5.9+ Observation framework) for reactive data binding
- `List` / `ScrollView` with lazy loading for performant history browsing
- `TextEditor` / `Label` for content preview
- `NSViewRepresentable` bridge for any AppKit-specific needs (menu bar integration)
- `Settings` scene for preferences window

### AppKit Bridge (Minimal)
Certain features require AppKit interop via `NSViewRepresentable` / `NSViewControllerRepresentable`:
- **Menu Bar Status Item**: `NSStatusBar` / `NSStatusItem`
- **Global Hotkey Registration**: `NSEvent.addGlobalMonitorForEvents` or Carbon `RegisterEventHotKey`
- **Custom Floating Panel**: `NSPanel` with `.nonactivatingPanel` style mask
- **Clipboard Monitoring**: `NSPasteboard` change count polling
- **Haptic Feedback**: `NSHapticFeedbackManager` for interaction confirmation
- **In-Memory Caching**: `NSCache` for decrypted thumbnail storage

## Data Storage

### GRDB.swift (SQLite)
**GRDB** is a mature, performant Swift SQLite toolkit providing:
- Type-safe query interface with Swift's `Codable`
- Full-Text Search (FTS5) with prefix matching and diacritics removal for instant, optimized clipboard content search
- Database observation via `ValueObservation` — SwiftUI views reactively update on database changes
- WAL mode for concurrent reads during writes
- Migration support for schema evolution

### CryptoKit
Apple's built-in cryptography framework for at-rest encryption:
- **AES-GCM** encryption for the SQLite database file
- Key stored in the Keychain (`SecItemAdd` with `kSecAttrAccessible = .whenUnlocked`)
- Encryption/decryption transparent at the storage layer — app logic works with plain data
- No third-party crypto dependencies required

### Keychain
- `SecItem` API for secure credential and encryption key storage
- App-specific keychain access group
- Keys survive app deletion (unless user explicitly removes)

## Build System & Dependencies

### Xcode 16+
- Primary IDE and build system
- Project configuration via `.xcodeproj`
- Code signing and notarization for distribution
- Test plans for unit, integration, and UI tests

### Swift Package Manager (SPM)
All dependencies managed via SPM — no CocoaPods or Carthage.

| Package | Purpose | Version |
|---------|---------|---------|
| GRDB.swift | SQLite database with FTS5 search | ~> 6.0 |
| (CryptoKit) | Built-in — no package needed | Apple SDK |
| (Combine) | Built-in — reactive data flow | Apple SDK |

### Minimum Deployment Target
- **macOS 14.0 (Sonoma)** — enables SwiftUI improvements, SwiftData option, and Swift 5.9+ Observation framework

## Testing

### Frameworks
- **XCTest** — Apple's built-in testing framework for unit and UI tests
- **SwiftUI Preview Tests** — Snapshot-style verification using Xcode Previews

### Test Categories
1. **Unit Tests**: Storage layer, clipboard parsing, content type detection, encryption/decryption
2. **Integration Tests**: Pasteboard monitoring, search indexing, iPhone handoff detection
3. **UI Tests**: Menu bar interaction, panel navigation, keyboard shortcuts

## Development Tools

- **SwiftLint**: Linting for consistent code style
- **SwiftFormat**: Automatic code formatting
- **Xcode Cloud** (optional): CI/CD for building, testing, and distribution
