//
//  ContentCacheTests.swift
//  ClipVaultTests
//

import XCTest
@testable import ClipVault

final class ContentCacheTests: XCTestCase {
    
    override func setUpWithError() throws {
        ContentCache.shared.clear()
    }
    
    override func tearDownWithError() throws {
        ContentCache.shared.clear()
    }
    
    func testCache_EvictsBasedOnFixedCostLimit() {
        let cache = ContentCache.shared
        
        // Arrange: Insert 50 entries
        // Total cost will be 50 * 500KB = 25MB (exceeds 20MB limit)
        // Count limit is 100, so without cost eviction, they would all stay.
        for i in 1...50 {
            var entry = ClipboardEntry(timestamp: Date(), contentType: .text)
            entry.id = Int64(i)
            cache.set(entry, for: Int64(i))
        }
        
        // Assert: Early items should be evicted due to totalCostLimit
        let firstEntry = cache.get(for: 1)
        XCTAssertNil(firstEntry, "Early entry should have been evicted due to fixed cost limit")
    }
}
