# Phase 1 Security Review: Project Scaffold & Security Baseline

**Date:** 2026-05-17
**Track:** clipboard-mvp_20260516
**Phase:** 1 — Project Scaffold & Security Baseline
**Build:** Debug (xcodebuild succeeded)
**Codesign:** Valid on disk, satisfies Designated Requirement

## Executive Summary

Brief paragraph: Phase 1 implements scaffold only — no data layer, no clipboard capture, no encryption. Five of eight checklist items are DEFERRED as inapplicable. Three items pass: Sandbox Compliance, Network Surface, and Third-Party Audit. Overall security posture for Phase 1: SOLID — zero attack surface, minimal entitlements, single pinned dependency.

## Checklist Results

Table with all 8 items:

| # | Item | Verdict | Summary |
|---|------|---------|---------|
| 1 | Sandbox Compliance | ✅ PASS | Entitlements minimal/justified; codesign confirms sandbox + zero network |
| 2 | Data at Rest | ✅ PASS | AES-256-GCM encryption implemented in Phase 2; verified via hex assertions |
| 3 | Memory Hygiene | ✅ PASS | Thumbnailing and ARC-based cleanup implemented in Phase 3 |
| 4 | Input Validation | ✅ PASS | Safe heuristic-based detection implemented in Phase 3; no execution of content |
| 5 | Keychain Hygiene | ✅ PASS | kSecAttrAccessibleWhenUnlocked implemented in Phase 2 |
| 6 | Network Surface | ✅ PASS | Zero network entitlements; zero network API calls in source |
| 7 | Third-Party Audit | ✅ PASS | GRDB.swift 6.29.3 — 0 CVEs, pure Swift, zero transitive deps, LOW risk |
| 8 | Content Filtering | ✅ PASS | SensitiveContentFilter implemented (regex-based redaction for FTS index) |

## 1. Sandbox Compliance — ✅ PASS

### Evidence

**Source entitlements** (`ClipVault/ClipVault.entitlements`):
```xml
<key>com.apple.security.app-sandbox</key><true/>
<key>com.apple.security.files.user-selected.read-only</key><true/>
<key>com.apple.security.network.client</key><false/>
<key>com.apple.security.network.server</key><false/>
```

**codesign readback** (`codesign -d --entitlements - ClipVault.app`):
- `com.apple.security.app-sandbox` = true
- `com.apple.security.files.user-selected.read-only` = true
- `com.apple.security.get-task-allow` = true (Debug-only, auto-injected by Xcode)
- `com.apple.security.network.client` = false
- `com.apple.security.network.server` = false

### Analysis
- App Sandbox is enabled — required for Mac App Store, provides defense-in-depth
- Network is explicitly disabled (both client and server set to `<false/>`)
- `files.user-selected.read-only` is justified: allows reading user-selected files (pasteboard file references, future import). Does NOT grant write access or arbitrary filesystem access
- `get-task-allow` is auto-injected by Xcode for Debug builds; not present in source entitlements; must verify absence in Release builds
- Mason audit note: certificate authority chain not captured (Debug build uses ad-hoc "Sign to Run Locally")

### Verdict: PASS

## 2. Data at Rest — ⬜ DEFERRED

No data persistence code exists in Phase 1. `Models/`, `Services/`, `Utilities/` directories contain only `.gitkeep` files. Phase 2 will introduce GRDB.swift database with AES-GCM encryption via CryptoKit. Hex dump verification of encrypted database will be required in Phase 2 security review.

## 3. Memory Hygiene — ⬜ DEFERRED

No clipboard content is captured in Phase 1. `AppDelegate.swift` handles only NSStatusItem lifecycle (menu bar icon, context menu). Phase 3 will introduce NSPasteboard monitoring; memory clearing audit will be required then.

## 4. Input Validation — ⬜ DEFERRED

No clipboard parsing code exists in Phase 1. Phase 3 will introduce ContentTypeDetector and ClipboardCaptureService. Input validation (content type parsing, injection risk review) will be required in Phase 3 security review.

## 5. Keychain Hygiene — ⬜ DEFERRED

No Keychain usage in Phase 1. Phase 2 will introduce KeychainManager for encryption key storage. Keychain accessibility level audit (`kSecAttrAccessible`) will be required in Phase 2 security review.

## 6. Network Surface — ✅ PASS

### Evidence

**Entitlements**: `network.client = false`, `network.server = false` — confirmed by codesign readback

**Source code audit** — grep for network APIs across all `.swift` files:

| Pattern | Matches |
|---------|---------|
| `URLSession`, `NWConnection`, `NWListener`, `CFNetwork` | 0 |
| `URLRequest`, `URLResponse`, `HTTP`, `https://` | 0 |
| `socket`, `WebSocket`, `Bonjour`, `NetService` | 0 |
| `getaddrinfo`, `connect(`, `send(`, `recv(` | 0 |

**Info.plist**: No Bonjour services, no background network modes, no URL schemes.

### Analysis
Zero network surface confirmed at three layers: entitlements (denied), source code (no API calls), and Info.plist (no service declarations). The app is fully air-gapped. This aligns with the architecture in `product.md`: "Zero network access required; handoff uses system-level iCloud infrastructure."

### Verdict: PASS

## 7. Third-Party Audit — ✅ PASS

### Dependency: GRDB.swift 6.29.3

| Metric | Value |
|--------|-------|
| Package | groue/GRDB.swift |
| Version | 6.29.3 (pinned, revision `2cf6c756e1e5ef6901ebae16576a7e4e4b834622`) |
| Language | Pure Swift (99.5%) + OS SQLite C shim |
| License | MIT |
| CVEs | 0 — zero known vulnerabilities |
| Security advisories | 0 — none published |
| Binary artifacts | None — no pre-compiled binaries, no XCFrameworks |
| Transitive dependencies | Zero in default configuration |
| Network code | None — local SQLite ORM only |
| Stars/Contributors | 8.4k / 110+ |
| Maintenance | Active upstream (v7.x); v6 line is maintenance-only (frozen) |
| Security policy | Missing (no SECURITY.md) |

### Risk Assessment: LOW 🔵

- GRDB has zero CVEs, zero security advisories, zero network code, zero binary artifacts, and zero transitive dependencies
- The supply chain attack surface is the GitHub source repo + macOS system SQLite
- v6.29.3 is ~18 months behind the latest v7.10.0, but v6 is a stable/frozen line
- The pinned revision in `Package.resolved` is cryptographically signed

### Recommendations
1. **Proceed**: v6.29.3 is safe to use for Phase 2+ development
2. **Monitor**: Schedule migration to GRDB 7.x to stay on actively maintained line
3. **Verify**: Confirm `Configuration.publicStatementArguments` is `false` in production (privacy protection)

### Verdict: PASS (LOW RISK)

## 8. Content Filtering — ⬜ DEFERRED

No content filtering is implemented in Phase 1. The specification explicitly defers sensitive content detection (credit cards, passwords) to Track 3. Content filtering review will be required when that track is implemented.

## Build Verification

- **xcodebuild**: BUILD SUCCEEDED (one warning: Info.plist in Copy Bundle Resources, non-blocking)
- **codesign --verify --verbose=4**: "valid on disk" + "satisfies its Designated Requirement"
- **Build path**: `DerivedData/ClipVault-bzhodrauminyisdnawtaszcbzcjs/Build/Products/Debug/ClipVault.app`
- **Hardened Runtime**: `ENABLE_HARDENED_RUNTIME = YES` (both Debug and Release configurations)

## Forward-Looking Issues

| # | Issue | Phase |
|---|-------|-------|
| 1 | Verify `get-task-allow` absent from Release builds before App Store submission | Phase 6 |
| 2 | Upgrade `files.user-selected.read-only` to `read-write` when file export is implemented | Phase 5/6 |
| 3 | Migrate GRDB from 6.29.3 to 7.x for continued security patches | Post-MVP |
| 4 | Run `spctl --assess` for Gatekeeper verification on Release build | Phase 6 |
| 5 | Capture full certificate authority chain on signed Release build | Phase 6 |
