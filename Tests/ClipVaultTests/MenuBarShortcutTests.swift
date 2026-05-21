//
//  MenuBarShortcutTests.swift
//  ClipVaultTests
//

import XCTest
@testable import ClipVault

@MainActor
final class MenuBarShortcutTests: XCTestCase {
    private var controller: MenuBarController!
    private var viewModel: ClipboardViewModel!
    private var repository: ClipboardRepository!
    
    override func setUp() {
        super.setUp()
        let db = DatabaseManager(inMemory: true)
        repository = ClipboardRepository(dbManager: db)
        viewModel = ClipboardViewModel(repository: repository)
        controller = MenuBarController(viewModel: viewModel)
    }
    
    func testZoomShortcuts() {
        let settings = SettingsManager.shared
        settings.zoomLevel = 1.0
        
        // Cmd + Plus
        let zoomIn = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: .command, timestamp: 0, windowNumber: 0, context: nil, characters: "+", charactersIgnoringModifiers: "+", isARepeat: false, keyCode: 24)!
        _ = controller.handleKeyDown(zoomIn)
        XCTAssertGreaterThan(settings.zoomLevel, 1.0)
        
        // Cmd + Minus
        let zoomOut = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: .command, timestamp: 0, windowNumber: 0, context: nil, characters: "-", charactersIgnoringModifiers: "-", isARepeat: false, keyCode: 27)!
        _ = controller.handleKeyDown(zoomOut)
        XCTAssertEqual(settings.zoomLevel, 1.0, accuracy: 0.01)
        
        // Cmd + 0
        settings.zoomLevel = 1.5
        let resetZoom = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: .command, timestamp: 0, windowNumber: 0, context: nil, characters: "0", charactersIgnoringModifiers: "0", isARepeat: false, keyCode: 29)!
        _ = controller.handleKeyDown(resetZoom)
        XCTAssertEqual(settings.zoomLevel, 1.0, accuracy: 0.01)
    }
    
    func testCmdW_DismissesPanel() {
        controller.togglePanel()
        XCTAssertTrue(controller.isPanelVisible)
        
        let cmdW = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: .command, timestamp: 0, windowNumber: 0, context: nil, characters: "w", charactersIgnoringModifiers: "w", isARepeat: false, keyCode: 13)!
        _ = controller.handleKeyDown(cmdW)
        
        XCTAssertFalse(controller.isPanelVisible)
    }
}
