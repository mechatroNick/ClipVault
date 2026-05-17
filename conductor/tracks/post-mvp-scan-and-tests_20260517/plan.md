# Implementation Plan: Post-MVP Scan & Edge-Case Tests

## Phase 1: Security & Vulnerability Remediation

- [x] Task: Run automated dependency scan
    - [x] Execute `osv-scanner` on the project root.
    - [x] Analyze results and identify vulnerable packages.
    - [x] Update dependencies to secure versions.
    - [x] Verify: Scan report is clean.
    - [x] Commit: `security: Update dependencies to remediate vulnerabilities`

- [x] Task: Perform static security analysis
    - [x] Scan for hardcoded secrets, insecure API usage, and PII leaks in logs.
    - [x] Audit `SensitiveContentFilter` effectiveness.
    - [x] Remediate any identified issues.
    - [x] Commit: `security: Remediate static analysis findings`

## Phase 2: Deferred Feature Implementation

- [x] Task: Implement Markdown preview rendering
    - [x] Add a lightweight markdown parsing library or implement basic regex-based styling.
    - [x] Update `TextPreview` to render styled markdown.
    - [x] Verify: Markdown elements (headers, bold, lists) are visually distinct.
    - [x] Commit: `feat(ui): Add basic markdown rendering to history panel`

- [x] Task: Add Universal Clipboard detection
    - [x] Research `NSPasteboard.PasteboardType` or metadata for Handoff content.
    - [x] Update `ClipboardCaptureService` to detect Handoff source.
    - [x] Update UI to show a device icon for remote copies.
    - [x] Commit: `feat(clipboard): Detect and badge Universal Clipboard entries`

- [x] Task: Enhance Sensitive Content Filtering
    - [x] Expand regex patterns in `SensitiveContentFilter`.
    - [x] Add support for custom user-defined patterns (stored in `SettingsManager`).
    - [x] Verify: New patterns are redacted in the search index.
    - [x] Commit: `feat(security): Enhance SensitiveContentFilter with custom patterns`

## Phase 3: Edge-Case Test Suite

- [x] Task: Generate and implement stress tests
    - [x] Create tests for rapid clipboard updates (e.g., 50 copies in 1 second).
    - [x] Create tests for very large text (>50MB) and image (>100MB) content.
    - [x] Verify: App remains responsive and memory usage stays within bounds.
    - [x] Commit: `test: Add stress tests for clipboard monitoring and storage`

- [x] Task: Implement failure-mode tests
    - [x] Mock Keychain failures to verify graceful handling.
    - [x] Mock Database disk-full or corruption scenarios.
    - [x] Verify: App does not crash and provides clear error state where applicable.
    - [x] Commit: `test: Add failure-mode tests for Keychain and Database`

- [x] Task: Final verification
    - [x] Run the complete test suite (original MVP + new edge cases).
    - [x] Verify ≥95% coverage is maintained.
    - [x] Commit: `test: Final verification of post-MVP scan and tests`

## Phase 4: Lifecycle & Performance Hardening

- [x] Task: Enforce singleton application instance
    - [x] Implement `NSApplication` delegate check or use `NSRunningApplication` to detect existing instance.
    - [x] Handle second launch: focus first instance, show menu bar icon, and terminate current.
    - [x] Commit: `chore(lifecycle): Ensure app runs as singleton`

- [x] Task: Fix and harden application exit logic
    - [x] Verify "Quit ClipVault" menu item triggers `NSApplication.terminate`.
    - [x] Implement cleanup logic: stop `PasteboardMonitor`, cancel `streamTask` in `ClipboardCaptureService`.
    - [x] Verify ⌘Q works as expected.
    - [x] Commit: `chore(lifecycle): Implement reliable application exit`

- [x] Task: Tune performance for extreme clipboard content
    - [x] Benchmark capture of 10,000 files/folders.
    - [x] Optimize `ContentTypeDetector` and `ClipboardCaptureService` for massive IO (non-blocking metadata extraction).
    - [x] Implement lazy loading/incremental capture for folder structures.
    - [x] Verify: System remains responsive during 4GB file copies.
    - [x] Commit: `perf: Optimize capture pipeline for extreme cases`

- [x] Task: Conductor - User Manual Verification 'Post-MVP Scan & Edge-Case Tests' (Protocol in workflow.md)
