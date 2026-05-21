# Implementation Plan: Search Truncation and Cache Fixes

## Phase 1: Search Index Bug Fix
- [ ] Task: Fix FTS index truncation
    - [ ] Write regression test reproducing the FTS search bug for entries > 200 characters
    - [ ] Implement fix by removing `.prefix(200)` truncation in `ClipboardRepository.swift` (or using a much larger safe threshold)
    - [ ] Verify regression test passes
    - [ ] Verify no existing tests break
- [ ] Task: Conductor - User Manual Verification 'Phase 1: Search Index Bug Fix' (Protocol in workflow.md)

## Phase 2: Cache Cost Limit Fix
- [ ] Task: Fix ineffective cache memory limit
    - [ ] Write regression test reproducing the unbounded cache memory usage (missing cost metric)
    - [ ] Implement fix by calculating heuristic cost and using `cache.setObject(_:forKey:cost:)` in `ContentCache.swift`
    - [ ] Verify regression test passes
    - [ ] Verify no existing tests break
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Cache Cost Limit Fix' (Protocol in workflow.md)
