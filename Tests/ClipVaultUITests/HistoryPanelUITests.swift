//
//  HistoryPanelUITests.swift
//  ClipVaultUITests
//

import XCTest

final class HistoryPanelUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
    }

    func testPanelToggleWithHotkey() throws {
        let app = XCUIApplication()
        
        // Simulate Cmd+Shift+V
        // Note: Global hotkeys are hard to trigger in standard XCUITest.
        // We usually test the internal logic via Unit Tests and 
        // use UI tests for elements we can interact with.
        
        // Let's check if the status item exists
        let statusItem = app.statusItems["ClipVault"]
        XCTAssertTrue(statusItem.exists)
        
        // Click status item to open panel
        statusItem.click()
        
        // Check if search bar exists in the panel
        let searchField = app.textFields["Search history..."]
        XCTAssertTrue(searchField.waitForExistence(timeout: 2))
    }
}
