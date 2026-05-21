# Security Review — Phase 3: Settings & Privacy Overhaul

**Track:** App Polish and New Features V1.5  
**Phase:** Phase 3 — Settings & Privacy Overhaul  
**Date:** 2026-05-21  
**Reviewer:** Conductor (Automated Security Review)

---

## Checklist Results

| # | Item | Status | Notes |
|---|------|--------|-------|
| 1 | Sandbox Compliance | ✅ PASS | No new entitlements added. `HotkeyRecorderView` uses only local `NSEvent` monitor (no cross-process APIs). `PrivacyIgnoreList` is in-process only. |
| 2 | Data at Rest | ✅ PASS | `ignoredBundleIDs` is stored in `UserDefaults` as a plain string array (not sensitive). `globalHotkey` stored as JSON in `UserDefaults` (not sensitive — it is UI config, not a key). No clipboard content is involved in these new settings. |
| 3 | Memory Hygiene | ✅ PASS | No plaintext clipboard content is introduced by Phase 3 changes. `HotkeyRecorderView`'s local event monitor is unregistered in `onDisappear`. |
| 4 | Input Validation | ✅ PASS | Bundle IDs in the ignore list are treated as opaque strings; no code execution from them occurs. The `isIgnored(bundleID:in:)` performs a simple lowercased string comparison — no injection risk. |
| 5 | Keychain Hygiene | ✅ PASS | Phase 3 introduces no new Keychain interactions. Encryption keys remain unchanged. |
| 6 | Network Surface | ✅ PASS | Phase 3 changes are entirely local. No network access added. |
| 7 | Third-Party Audit | ✅ PASS | No new third-party dependencies added. Uses only Apple frameworks (AppKit, Carbon, SwiftUI, Combine, Foundation). |
| 8 | Content Filtering | ✅ PASS | The Privacy Ignore List **enhances** content filtering by rejecting clipboard changes from nominated apps. The existing concealed-type filter (`org.nspasteboard.ConcealedType`) remains in place as a first line of defense. The ignore list acts as a second, user-configurable layer. |

---

## Key Design Decisions

### Privacy Ignore List Implementation
The ignore list check (`PrivacyIgnoreList.isIgnored`) is placed **before** content type detection in `ClipboardCaptureService.captureCurrentPasteboard()`. This means:
- Clipboard data from ignored apps is **never read or processed** by ClipVault.
- No clipboard content from ignored apps enters memory, even transiently.
- This is a defense-in-depth measure alongside the existing `org.nspasteboard.ConcealedType` detection.

### Global Hotkey Storage
The `HotkeyDescriptor` is stored as JSON in `UserDefaults`. This is **not** a security-sensitive value — it is user interface configuration (a key code and modifier flags). No credentials, tokens, or private data are involved.

### HotkeyRecorderView Event Monitor
The `HotkeyRecorderView` installs a **local** `NSEvent` monitor (not a global one). Local monitors only receive events when the application is frontmost, which is the correct behavior for a recording UI in a settings window. The monitor is cleaned up in `onDisappear` to prevent leaks.

---

## Verdict

✅ **Phase 3 passes the security review.** No regressions were introduced and the Privacy Ignore List feature actively improves the privacy posture of ClipVault.
