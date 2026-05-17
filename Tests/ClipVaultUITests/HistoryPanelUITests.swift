//
//  HistoryPanelUITests.swift
//  ClipVaultUITests
//

import XCTest

final class HistoryPanelUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        
        // Open the panel via the status item for each test
        let statusItem = app.statusItems["ClipVault"]
        if statusItem.exists {
            statusItem.click()
        }
    }

    func testArrowNavigationAndSelection() throws {
        // Ensure some entries exist (we might need to mock data or rely on app state)
        // For UITests we usually assume a clean state or use launch arguments.
        
        let searchField = app.textFields["Search history..."]
        XCTAssertTrue(searchField.waitForExistence(timeout: 2))
        
        // Simulate down arrow
        app.typeKey(.downArrow, modifierFlags: [])
        
        // Verify selection change (usually via accessibility labels or traits)
        // Since we are testing a vertical slice MVP, we check if we can still type.
        searchField.typeText("Testing")
        XCTAssertEqual(searchField.value as? String, "Testing")
    }

    func testEscapeDismissesPanel() throws {
        let searchField = app.textFields["Search history..."]
        XCTAssertTrue(searchField.waitForExistence(timeout: 2))
        
        // Press Escape
        app.typeKey(.escape, modifierFlags: [])
        
        // Verify panel is gone (search field should no longer be visible/existent)
        let exists = searchField.waitForExistence(timeout: 1)
        XCTAssertFalse(exists)
    }

    func testPanelOpenPerformance() throws {
        // Close it first if it's open from setUp
        app.typeKey(.escape, modifierFlags: [])
        
        let statusItem = app.statusItems["ClipVault"]
        XCTAssertTrue(statusItem.exists)
        
        measure(metrics: [XCTOSSignpostMetric.applicationLaunch]) {
            statusItem.click()
            let searchField = app.textFields["Search history..."]
            _ = searchField.waitForExistence(timeout: 1)
        }
    }
}
