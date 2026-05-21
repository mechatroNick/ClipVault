import XCTest
import SwiftUI
@testable import ClipVault

@MainActor
final class EmptyStateViewTests: XCTestCase {
    
    func testEmptyStateView_Initializes() {
        let view = EmptyStateView()
        XCTAssertNotNil(view.body)
    }
}
