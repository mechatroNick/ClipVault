# Implementation Plan: Clipboard MVP

## Phase 1: Project Scaffold & Security Baseline

- [x] Task: Initialize Xcode project with Swift Package Manager
    - [x] Create macOS app target (SwiftUI App lifecycle, macOS 14.0+)
    - [x] Add GRDB.swift dependency via SPM
    - [x] Configure Info.plist: LSUIElement = YES (no dock icon)
    - [x] Create directory structure: Models/, Services/, Views/, Utilities/, Tests/
    - [x] Add .gitignore (Xcode, SwiftPM, macOS artifacts)
    - [x] Add .swiftlint.yml with project rules
    - [x] Verify: project builds with `xcodebuild -scheme ClipVault -destination 'platform=macOS' build`
    - [x] Commit: `chore(build): Initialize Xcode project with SPM and project structure`

- [x] Task: Configure App Sandbox and security entitlements
    - [x] Write unit tests verifying entitlement absence (no network, no file read/write outside sandbox)
    - [x] Enable App Sandbox capability in Xcode
    - [x] Configure entitlements: com.apple.security.app-sandbox = true
    - [x] Explicitly disable: com.apple.security.network.client, com.apple.security.network.server
    - [x] Add com.apple.security.files.user-selected.read-only for file reference access
    - [x] Verify: `codesign -d --entitlements -` shows sandbox and no network entitlements
    - [x] Verify: app launches sandboxed without crashes
    - [x] Commit: `security(build): Enable App Sandbox with minimal entitlements, zero network`

- [x] Task: Implement app entry point and menu bar lifecycle
    - [x] Write unit tests for app delegate lifecycle (menu bar item creation)
    - [x] Create AppDelegate: register NSStatusItem, configure template icon
    - [x] Configure SwiftUI App scene with MenuBarExtra (macOS 14+)
    - [x] Implement right-click context menu (Settings, Quit)
    - [x] Ensure no dock icon appears (LSUIElement)
    - [x] Run test suite, verify ≥95% coverage for new code
    - [x] Commit: `feat(ui): Add menu bar status item with context menu`

- [x] Task: Conductor - User Manual Verification 'Phase 1: Project Scaffold & Security Baseline' (Protocol in workflow.md)

## Phase 2: Data Layer & Encryption

- [x] Task: Define GRDB database schema and migrations
    - [x] Write unit tests for schema creation (all tables, indexes, constraints)
    - [x] Write unit tests for migration (v1 → v2 if applicable)
    - [x] Create DatabaseManager with GRDB DatabaseQueue (WAL mode)
    - [x] Define ClipboardEntry model (Codable, FetchableRecord, PersistableRecord)
    - [x] Create initial migration: clipboard_entries table with all columns
    - [x] Add FTS5 virtual table for full-text search on plainTextPreview
    - [x] Implement database path resolution in app sandbox container
    - [x] Run test suite, verify ≥95% coverage
    - [x] Commit: `feat(storage): Add GRDB database schema with FTS5 search`

- [x] Task: Implement AES-GCM encryption service
    - [x] Write unit tests for encrypt/decrypt roundtrip with known vectors
    - [x] Write unit tests for tampered data detection (decryption failure)
    - [x] Create EncryptionService using CryptoKit AES.GCM
    - [x] Implement encrypt(data: Data) -> Data and decrypt(data: Data) -> Data
    - [x] Handle SealedBox combined format (nonce + ciphertext + tag)
    - [x] Run test suite, verify ≥95% coverage
    - [x] Commit: `feat(security): Add AES-GCM encryption service via CryptoKit`

- [x] Task: Integrate Keychain for encryption key management
    - [x] Write unit tests for key generation, storage, retrieval, and deletion
    - [x] Write unit tests for key persistence across app restarts
    - [x] Create KeychainManager using SecItem API
    - [x] Generate 256-bit SymmetricKey on first launch, store in Keychain
    - [x] Retrieve key on subsequent launches; regenerate if missing
    - [x] Configure kSecAttrAccessible = .whenUnlocked
    - [x] Implement key deletion for app reset
    - [x] Run test suite, verify ≥95% coverage
    - [x] Commit: `feat(security): Add Keychain-backed encryption key management`

- [x] Task: Build encrypted clipboard entry repository
    - [x] Write unit tests for CRUD operations with encryption layer
    - [x] Write integration tests: store entry → encrypt → decrypt → retrieve → verify content
    - [x] Create ClipboardRepository combining DatabaseManager + EncryptionService
    - [x] Implement save(entry) — encrypts content before DB write
    - [x] Implement fetchAll(), fetch(id), search(query), delete(id), pin(id), unpin(id)
    - [x] Implement auto-purge of expired entries based on retention setting
    - [x] Run full test suite, verify ≥95% coverage
    - [x] Verify: database file hex dump shows no plain text
    - [x] Commit: `feat(storage): Add encrypted clipboard entry repository`

- [x] Task: Conductor - User Manual Verification 'Phase 2: Data Layer & Encryption' (Protocol in workflow.md)

## Phase 3: Clipboard Monitoring & Capture

- [x] Task: Implement pasteboard change monitoring
    - [x] Write unit tests for change detection (mock NSPasteboard)
    - [x] Write integration tests: simulate copy → verify change detected
    - [x] Create PasteboardMonitor using Timer-based change count polling (500ms interval)
    - [x] Detect NSPasteboard.general changeCount increments
    - [x] Filter self-copies (entries originating from the app itself)
    - [x] Emit changes via AsyncSequence (AsyncStream) for reactive consumers
    - [x] Implement app lifecycle awareness (pause monitoring when inactive, resume on active)
    - [x] Run test suite, verify ≥95% coverage
    - [x] Commit: `feat(clipboard): Add NSPasteboard change monitoring with AsyncStream`

- [x] Task: Build content type detection engine
    - [x] Write unit tests for each content type (text, rtf, image, file, url, markdown, code, unknown)
    - [x] Write unit tests for edge cases (empty clipboard, binary data, very long strings)
    - [x] Create ContentTypeDetector with detection heuristics
    - [x] Check NSPasteboard.PasteboardType availability in priority order
    - [x] Detect markdown: heuristics on text content (# headers, **bold**, [links](), ```fences)
    - [x] Detect code: indentation patterns, keywords, operator density
    - [x] Detect images: NSPasteboard.PasteboardType.tiff, .png
    - [x] Detect files: NSPasteboard.PasteboardType.fileURL
    - [x] Run test suite, verify ≥95% coverage
    - [x] Commit: `feat(clipboard): Add content type detection with markdown and code heuristics`

- [x] Task: Implement clipboard entry creation pipeline
    - [x] Write integration tests: copy text → pipeline creates entry → entry in repository
    - [x] Write unit tests for large file threshold logic
    - [x] Create ClipboardCaptureService: orchestrate monitor → detect → extract → store
    - [x] Extract plain text preview (first 200 chars) for all text types
    - [x] Generate thumbnail data for images (NSImage resize to 48px)
    - [x] Handle large files: identify size, prepare for Vault storage (Phase 5)
    - [x] Capture source application bundle identifier
    - [x] Run full test suite, verify ≥95% coverage
    - [x] Verify: capture latency <100ms (integration test timing assertion)
    - [x] Task: Implement baseline sensitive content filtering (deferred task)
        - [x] Create SensitiveContentFilter with regex-based redaction
        - [x] Integrate filter into ClipboardRepository.save() to protect FTS index
        - [x] Write unit tests for redaction of Credit Cards, SSNs, and Secrets
        - [x] Commit: `feat(security): Implement SensitiveContentFilter for search index protection`
    - [x] Commit: `feat(clipboard): Add clipboard entry creation pipeline with large file handling`

- [x] Task: Conductor - User Manual Verification 'Phase 3: Clipboard Monitoring & Capture' (Protocol in workflow.md)

## Phase 4: Menu Bar UI & History Panel

- [x] Task: Build history panel SwiftUI view hierarchy
    - [x] Write unit tests for ClipboardViewModel state management
    - [x] Write UI tests for panel open/close behavior
    - [x] Create ClipboardViewModel (@Observable): entries list, search query, selected index
    - [x] Create HistoryPanelView: List with ClipboardEntryRow views
    - [x] Implement SearchBarView with real-time filtering
    - [x] Create EntryRowView: preview text, type badge, timestamp, source app icon
    - [x] Connect to ClipboardRepository for data (reactive via ValueObservation)
    - [x] Implement entry selection highlighting
    - [x] Run test suite, verify ≥95% coverage
    - [x] Commit: `feat(ui): Add history panel with search and entry list`

- [x] Task: Implement content preview rendering
    - [x] Write unit tests for each preview renderer
    - [x] Create TextPreview: first 3 lines with ellipsis, monospace for code
    - [x] Create ImagePreview: 48px NSImage thumbnail with filename overlay
    - [x] Create FilePreview: icon + filename + size + path
    - [x] Create URLPreview: domain + page title (if available)
    - [x] Create ContentPreviewRouter that selects renderer based on contentType
    - [x] Run test suite, verify ≥95% coverage
    - [x] Commit: `feat(ui): Add content preview renderers for all clipboard types`

- [x] Task: Implement keyboard navigation and global hotkey
    - [x] Write unit tests for keyboard handler state machine
    - [x] Write UI tests for arrow navigation, Enter paste, Escape dismiss
    - [x] Create KeyboardHandler: manages focus, selection, and action dispatch
    - [x] Register global hotkey ⌘⇧V (use Carbon RegisterEventHotKey)
    - [x] Implement arrow key browsing (up/down changes selection)
    - [x] Implement Enter to paste selected entry
    - [x] Implement Escape: clear search first, then dismiss panel
    - [x] Implement ⌘1-9 quick paste, ⌘F focus search, ⌘⌫ delete
    - [x] Add visible focus rings on all interactive elements
    - [x] Run test suite, verify ≥95% coverage
    - [ ] Verify: panel opens in <200ms from hotkey (UI test timing)
    - [x] Commit: `feat(ui): Add keyboard navigation and ⌘⇧V global hotkey`

- [x] Task: Integrate menu bar with history panel
    - [ ] Write integration tests: menu bar click → panel appears → keyboard nav → dismiss
    - [x] Create MenuBarController: manages NSPanel lifecycle
    - [x] Configure NSPanel: .nonactivatingPanel, .hudWindow, floats above others
    - [x] Position panel anchored below menu bar status item
    - [x] Implement panel show/hide animation (fade + slide)
    - [x] Implement click-outside-to-dismiss
    - [x] Handle multiple monitor positioning
    - [ ] Run full test suite, verify ≥95% coverage
    - [x] Commit: `feat(ui): Integrate menu bar with floating history panel`

- [x] Task: Conductor - User Manual Verification 'Phase 4: Menu Bar UI & History Panel' (Protocol in workflow.md)

## Phase 5: Paste Integration & Polish

- [ ] Task: Implement paste-back functionality
    - [x] Write unit tests for pasteboard write operations
    - [ ] Write integration tests: select entry → paste → verify frontmost app receives content
    - [ ] Create PasteService: write entry content to NSPasteboard.general
    - [ ] Support all content types for paste-back (text, RTF, image, file references)
    - [ ] Option to paste as plain text (strip formatting from rich text)
    - [ ] After paste, dismiss panel and return focus to frontmost app
    - [ ] Handle paste failure gracefully (e.g., file path no longer valid)
    - [x] Run test suite, verify ≥95% coverage
    - [ ] Commit: `feat(clipboard): Add paste-back with type-aware content restoration`

- [ ] Task: Implement entry management (delete, pin, purge)
    - [x] Write unit tests for delete, pin, unpin, and purge operations
    - [ ] Add delete button to entry row (swipe or ⌘⌫)
    - [ ] Add pin/unpin toggle to entry row
    - [ ] Implement delete confirmation for pinned entries
    - [ ] Implement auto-purge timer (runs on launch and every hour)
    - [ ] Purge respects retention setting and skips pinned entries
    - [x] Run test suite, verify ≥95% coverage
    - [x] Commit: `feat(ui): Add entry delete, pin, and auto-purge functionality`

- [ ] Task: Build settings window
    - [x] Write unit tests for settings persistence (UserDefaults)
    - [x] Write UI tests for settings window navigation
    - [ ] Create SettingsView (SwiftUI Settings scene, ⌘,)
    - [ ] General tab: retention period picker, size threshold slider, max entries stepper
    - [ ] Security tab: placeholder for content filtering (deferred), encryption status indicator
    - [ ] About tab: app version, build number, licenses
    - [ ] Create SettingsManager: UserDefaults wrapper with App Group support
    - [ ] Apply settings changes immediately (real-time reactivation)
    - [x] Run test suite, verify ≥95% coverage
    - [x] Commit: `feat(ui): Add settings window with retention, threshold, and max entries`

- [ ] Task: Implement Vault File Storage
    - [ ] Write unit tests for directory creation and date-based organization
    - [ ] Create `VaultManager`: manages `Documents/VaultClip/YYYY-MM` structure
    - [ ] Integrate Vault with `ClipboardCaptureService`: save large text/images to files
    - [ ] Update `ClipboardRepository` to store Vault file paths instead of DB blobs for large items
    - [ ] Add Vault location picker to `SettingsView`
    - [ ] Commit: `feat(storage): Add organized Vault storage with date-based subfolders`

- [ ] Task: Conductor - User Manual Verification 'Phase 5: Paste Integration & Polish' (Protocol in workflow.md)

## Phase 6: Final Verification & Delivery

- [ ] Task: Full test suite verification
    - [ ] Run `xcodebuild test -scheme ClipVault -destination 'platform=macOS'` — all tests pass
    - [ ] Generate coverage report, verify ≥95% line coverage
    - [ ] Fix any failing tests or uncovered branches
    - [ ] Commit: `test: Full suite passing with ≥95% coverage`

- [ ] Task: Security review — Phase 6
    - [ ] Sandbox Compliance: verify entitlements minimal and justified
    - [ ] Data at Rest: confirm AES-GCM encryption verified via hex dump
    - [ ] Memory Hygiene: audit clipboard content clearing on dismiss
    - [ ] Input Validation: review pasteboard content parsing for injection risks
    - [ ] Keychain Hygiene: verify key accessibility levels
    - [ ] Network Surface: confirm zero network entitlements and no connections
    - [ ] Third-Party Audit: review GRDB.swift for supply-chain risks
    - [ ] Content Filtering: document deferred status
    - [ ] Produce SECURITY_REVIEW.md with pass/fail for each item
    - [ ] Commit: `security: Phase 6 security review complete`

- [ ] Task: App Store readiness check
    - [ ] Verify sandbox compliance for App Review
    - [ ] Verify all entitlements documented and justified
    - [ ] Run `xcodebuild archive -scheme ClipVault -archivePath build/ClipVault.xcarchive`
    - [ ] Verify archive passes validation
    - [ ] Generate preliminary App Store Connect metadata stub
    - [ ] Commit: `chore(build): Archive validation and App Store readiness check`

- [ ] Task: Conductor - User Manual Verification 'Phase 6: Final Verification & Delivery' (Protocol in workflow.md)
