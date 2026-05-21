# Specification: Search Truncation and Cache Fixes

## Overview
This track addresses two primary bugs identified during a codebase review: 
1. FTS index truncation preventing search on large clipboard items.
2. Ineffective caching cost limit leading to potential unbounded memory growth.

## Functional Requirements
- **FTS Search Index Fix**:
  - The `plainTextSearchContent` field extraction in `ClipboardRepository.swift` must be increased from a 200-character limit to a safe high threshold (e.g. 500,000 chars).
  - The SensitiveContentFilter must be able to handle this increased size without causing extreme memory spikes or blocking the thread excessively.
- **Cache Cost Limit Fix**:
  - `ContentCache.swift` must provide a cost value when setting objects in `NSCache`.
  - A fixed heuristic cost per entry will be used rather than calculating precise byte size, to keep the cache logic simple and fast.

## Out of Scope
- Migrating the deprecated `CGWindowListCopyWindowInfo` API.
