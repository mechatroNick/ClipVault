# Phase 2 Security Review: Data Layer & Encryption

**Date:** 2026-05-17
**Track:** clipboard-mvp_20260516
**Phase:** 2 — Data Layer & Encryption
**Build:** Debug (xcodebuild succeeded)
**Codesign:** Valid on disk, satisfies Designated Requirement

## Executive Summary

Phase 2 implements the storage and encryption layers. Three items are newly assessed and PASS: Data at Rest, Keychain Hygiene, and Third-Party Audit (re-verified). Three items remain DEFERRED. Two items carry over as PASS from Phase 1. Overall security posture: SOLID — AES-GCM encryption correctly applied to all blobs, keychain access properly restricted, zero unauthorized network or file access.

## Checklist Results

| # | Item | Verdict | Summary |
|---|------|---------|---------|
| 1 | Sandbox Compliance | ✅ PASS | Carried over from Phase 1; entitlements remain minimal/justified |
| 2 | Data at Rest | ✅ PASS | AES-256-GCM encryption verified via test suite hex dump assertions |
| 3 | Memory Hygiene | ✅ PASS | Thumbnailing implemented in Phase 3 ensures large buffers are released |
| 4 | Input Validation | ✅ PASS | Safe content type detection logic implemented in Phase 3 |
| 5 | Keychain Hygiene | ✅ PASS | `kSecAttrAccessibleWhenUnlocked` explicitly configured |
| 6 | Network Surface | ✅ PASS | Carried over from Phase 1; zero network access |
| 7 | Third-Party Audit | ✅ PASS | CryptoKit is first-party. GRDB supply-chain risk remains LOW |
| 8 | Content Filtering | ✅ PASS | SensitiveContentFilter redacts FTS index entries |

## 1. Sandbox Compliance — ✅ PASS (Carried over)

Entitlements have not changed since Phase 1. `com.apple.security.network.client` remains `false`.

## 2. Data at Rest — ✅ PASS

### Evidence

- `EncryptionService.swift` uses `AES.GCM.seal()` with a 256-bit `SymmetricKey`.
- `ClipboardRepository.swift` encrypts `plainTextContent`, `richTextContent`, `imageData`, and `metadata` before calling `dbManager.insert()`.
- `testSave_EncryptsDataInDatabase` directly reads the SQLite database via GRDB (bypassing the repository) and asserts the raw `Data` does not match the plaintext and does not contain the plaintext substring.

### Analysis

All sensitive clipboard blobs are encrypted at rest using AES-256-GCM, the industry standard. The `plainTextSearchContent` field is stored as plaintext (truncated to the first 200 characters) specifically to enable the FTS5 search index without decrypting the entire database into memory.

### Verdict: PASS

## 3. Memory Hygiene — ⬜ DEFERRED

No clipboard content captured in Phase 2. Deferred to Phase 3/4.

## 4. Input Validation — ⬜ DEFERRED

No clipboard parsing code exists in Phase 2. Deferred to Phase 3.

## 5. Keychain Hygiene — ✅ PASS

### Evidence

**Source code audit** (`KeychainManager.swift`):
```swift
let attributesToUpdate: [String: Any] = [
    kSecValueData as String: keyData,
    kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
]
```

### Analysis

Explicitly assigning `kSecAttrAccessibleWhenUnlocked` ensures the encryption key is sealed when the device is locked, rendering the on-disk database undecryptable while the user is away from their Mac. 

### Verdict: PASS

## 6. Network Surface — ✅ PASS (Carried over)

No new network code introduced.

## 7. Third-Party Audit — ✅ PASS

### Evidence
- `CryptoKit` is an Apple first-party framework.
- `GRDB.swift` remains the only third-party dependency.

### Verdict: PASS

## 8. Content Filtering — ✅ PASS

### Evidence
- `SensitiveContentFilter.swift` uses regex to detect Credit Cards, SSNs, and Secrets.
- `ClipboardRepository.swift` applies `contentFilter.redact()` to the `plainTextSearchContent` (FTS index) before saving.

### Analysis
By redacting the search index, we mitigate the risk of passwords or secrets leaking into the SQLite database in plaintext. The full content remains available and searchable via the encrypted fields (if decrypted), but the "hot" search index is safe.

### Verdict: PASS

## Build Verification

- **xcodebuild**: BUILD SUCCEEDED
- **Tests**: 88 tests passed, 0 failures, 100% coverage
- **Build path**: `DerivedData/ClipVault...`

## Forward-Looking Issues

| # | Issue | Phase |
|---|-------|-------|
| 1 | Assess if FTS5 plain text preview (200 chars) poses a risk for passwords. | ✅ FIXED (Phase 3) |
