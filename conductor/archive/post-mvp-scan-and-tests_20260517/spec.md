# Specification: Post-MVP Scan & Edge-Case Tests

## Track ID
`post-mvp-scan-and-tests_20260517`

## Overview
This track focuses on enhancing the application's robustness and security beyond the initial MVP. It includes performing automated security scans to identify vulnerabilities, implementing deferred post-MVP features that enhance the core vertical slice, and generating a comprehensive suite of edge-case tests to ensure high reliability.

## Functional Requirements

### FR1: Automated Security Scans
- Utilize automated tools (OSV-Scanner, etc.) to scan for vulnerable dependencies.
- Perform static analysis for potential security flaws (e.g., insecure data handling, hardcoded secrets).
- Remediate identified critical and high-severity vulnerabilities.

### FR2: Implementation of Deferred Post-MVP Features
- **Markdown Rendering**: Implement basic markdown rendering in the history panel preview.
- **Universal Clipboard Awareness**: Detect when content originates from an iPhone/iPad via Universal Clipboard (Handoff) and display a distinct badge.
- **Advanced Content Filtering**: Extend the `SensitiveContentFilter` to support custom regex patterns and more comprehensive redaction for the search index.

### FR3: Edge-Case Testing
- Generate and implement a new set of tests covering:
    - Extremely large clipboard content (approaching or exceeding system limits).
    - Rapid-fire clipboard changes (stress testing the monitor and storage).
    - Database corruption scenarios and recovery.
    - Keychain access failures.
    - Sandbox boundary violations.
    - Malformed content types (e.g., invalid RTF, corrupted images).

### FR4: Lifecycle Hardening
- **Singleton Enforcement**: Ensure only one instance of ClipVault can run at a time. If a second instance is launched, it should focus the existing instance's menu bar icon and terminate.
- **Reliable Exit**: Ensure the "Quit ClipVault" menu item and ⌘Q correctly terminate the process, cancelling all background actors and monitors.

### FR5: Extreme Performance Optimization
- **Folder/File Depth Handling**: Optimize the capture pipeline for "Extreme" cases:
    - Copying a very large single file (>4GB).
    - Copying a folder with deep subfolder structures.
    - Copying a folder containing thousands of small files.
- **Zero-Impact Capture**: Ensure these operations do not hang the UI or cause noticeable system lag. Use non-blocking IO and incremental processing.

## Non-Functional Requirements

### NFR1: Security
- Zero known high/critical vulnerabilities in dependencies.
- Sub-100ms response for sensitive content filtering.

### NFR2: Reliability
- 100% pass rate for all new edge-case tests.
- Graceful degradation if the Vault or Keychain is inaccessible.

## Acceptance Criteria

1. Automated scan report shows zero critical/high vulnerabilities.
2. Markdown entries are rendered with basic styling (bold, italics, headers) in the preview.
3. Universal Clipboard items show an "iPhone" icon or badge.
4. Custom sensitive content patterns can be configured and are correctly redacted in search.
5. All new edge-case tests pass reliably.
6. Launching a second instance of the app fails and refocuses the original.
7. Choosing "Quit" terminates the app immediately and cleanly.
8. Copying a folder with 10,000 files completes capture in <500ms without UI stutter.
