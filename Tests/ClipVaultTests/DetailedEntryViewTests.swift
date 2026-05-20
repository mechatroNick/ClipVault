//
//  DetailedEntryViewTests.swift
//  ClipVaultTests
//

import XCTest
import SwiftUI
@testable import ClipVault

final class DetailedEntryViewTests: XCTestCase {
    func testDetailedEntryView_InitializesWithoutCrashing() {
        let entry = ClipboardEntry(timestamp: Date(), contentType: .text, plainTextContent: Data("Test".utf8))
        let repository = ClipboardRepository()
        let view = DetailedEntryView(entry: entry, repository: repository)
        XCTAssertNotNil(view)
    }
}
