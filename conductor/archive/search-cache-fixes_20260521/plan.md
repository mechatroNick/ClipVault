# Implementation Plan: Search Truncation and Cache Fixes

## Phase 1: Search Index Bug Fix
- [x] Task: Fix FTS index truncation
    - [x] Write regression test reproducing the FTS search bug for entries > 200 characters
    - [x] Implement fix by removing `.prefix(200)` truncation in `ClipboardRepository.swift` (or using a much larger safe threshold)
    - [x] Verify regression test passes
    - [x] Verify no existing tests break
- [x] Task: Conductor - User Manual Verification 'Phase 1: Search Index Bug Fix' (Protocol in workflow.md)

## Phase 2: Cache Cost Limit Fix
- [x] Task: Fix ineffective cache memory limit
    - [x] Write regression test reproducing the unbounded cache memory usage (missing cost metric)
    - [x] Implement fix by calculating heuristic cost and using `cache.setObject(_:forKey:cost:)` in `ContentCache.swift`
    - [x] Verify regression test passes
    - [x] Verify no existing tests break
- [x] Task: Conductor - User Manual Verification 'Phase 2: Cache Cost Limit Fix' (Protocol in workflow.md)
## Phase: Review Fixes
- [x] Task: Apply review suggestions
