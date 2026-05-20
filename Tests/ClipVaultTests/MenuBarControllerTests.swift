//
//  MenuBarControllerTests.swift
//  ClipVaultTests
//

import XCTest
@testable import ClipVault

@MainActor
final class MenuBarControllerTests: XCTestCase {
    
    private var controller: MenuBarController!
    private var viewModel: ClipboardViewModel!
    private var repository: ClipboardRepository!
    private var dbManager: DatabaseManager!
    private var encryptionService: EncryptionService!
    private var keychainManager: MockKeychainManager!

    override func setUpWithError() throws {
        try super.setUpWithError()
        dbManager = try DatabaseManager(path: ":memory:")
        encryptionService = try EncryptionService()
        keychainManager = MockKeychainManager()
        repository = ClipboardRepository(dbManager: dbManager, encryptionService: encryptionService, keychainManager: keychainManager)

        viewModel = ClipboardViewModel(repository: repository, pasteService: PasteService())
        controller = MenuBarController(viewModel: viewModel)
    }
    
    override func tearDownWithError() throws {
        
        controller = nil
        viewModel = nil
        repository = nil
        dbManager = nil
        encryptionService = nil
        keychainManager = nil
        try super.tearDownWithError()
    }
    
    func testTogglePanel_ChangesVisibility() async throws {
        // Assert initial state
        XCTAssertFalse(controller.isPanelVisible)
        
        // Act: Open
        controller.togglePanel()
        
        // Wait for open animation
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Assert: Panel should be visible
        XCTAssertTrue(controller.isPanelVisible)
        
        // Act: Close
        controller.togglePanel()
        
        // Wait for close animation
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Assert: Panel should be hidden
        XCTAssertFalse(controller.isPanelVisible)
    }
    
    func testArrowNavigation_UpdatesViewModelSelection() async throws {
        // Arrange: Add some entries
        var entry1 = ClipboardEntry(timestamp: Date(), contentType: .text, plainTextContent: Data("1".utf8))
        var entry2 = ClipboardEntry(timestamp: Date().addingTimeInterval(1), contentType: .text, plainTextContent: Data("2".utf8))
        try repository.save(&entry1)
        try repository.save(&entry2)
        
        // Open panel
        controller.togglePanel()
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Act: Down Arrow (keycode 125)
        let downEvent = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: 0, context: nil, characters: "", charactersIgnoringModifiers: "", isARepeat: false, keyCode: 125)!
        _ = controller.handleKeyDown(downEvent)
        
        // Assert
        XCTAssertEqual(viewModel.selectedIndex, 0) // First item selected
        
        // Act: Down Arrow again
        _ = controller.handleKeyDown(downEvent)
        XCTAssertEqual(viewModel.selectedIndex, 1)
    }
    
    func testEscapeKey_DismissesPanel() async throws {
        // Arrange
        controller.togglePanel()
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertTrue(controller.isPanelVisible)
        
        // Act: Escape (keycode 53)
        let escapeEvent = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: 0, context: nil, characters: "", charactersIgnoringModifiers: "", isARepeat: false, keyCode: 53)!
        _ = controller.handleKeyDown(escapeEvent)
        
        // Wait for close animation
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Assert
        XCTAssertFalse(controller.isPanelVisible)
    }
    
    func testPanelOpenPerformance() async throws {
        // We measure the time it takes to open the panel
        // Target: < 200ms
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        controller.togglePanel()
        
        // Wait for the panel to be visible (ignoring animation for logic timing)
        var isVisible = controller.isPanelVisible
        let timeout = 0.5
        let startWait = Date()
        while !isVisible && Date().timeIntervalSince(startWait) < timeout {
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
            isVisible = controller.isPanelVisible
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = (endTime - startTime) * 1000 // ms
        
        print("PERF: Panel open latency: \(duration)ms")
        XCTAssertTrue(isVisible, "Panel should be visible")
        XCTAssertLessThan(duration, 200.0, "Panel should open in less than 200ms")
        
        controller.togglePanel() // Close for next iteration/cleanup
    }
    
    func testHandleAction_RightClick_DoesNotTogglePanel() async throws {
        // Arrange
        let rightClickEvent = NSEvent.mouseEvent(
            with: .rightMouseUp,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            eventNumber: 0,
            clickCount: 1,
            pressure: 0
        )!
        
        XCTAssertFalse(controller.isPanelVisible)
        
        // Act
        controller.handleAction(event: rightClickEvent)
        
        // Assert: Panel should NOT be visible because it should show context menu instead
        XCTAssertFalse(controller.isPanelVisible)
    }
    
    func testHandleAction_LeftClick_TogglesPanel() async throws {
        // Arrange
        let leftClickEvent = NSEvent.mouseEvent(
            with: .leftMouseUp,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            eventNumber: 0,
            clickCount: 1,
            pressure: 0
        )!
        
        XCTAssertFalse(controller.isPanelVisible)
        
        // Act
        controller.handleAction(event: leftClickEvent)
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Assert
        XCTAssertTrue(controller.isPanelVisible)
    }

    func testHandleKeyDown_ZoomKeys_UpdatesZoomLevel() async throws {
        let settings = SettingsManager.shared
        settings.zoomLevel = 1.0
        
        controller.togglePanel()
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Act: Command + (keycode 24 is '+/=', but characters matter)
        let zoomInEvent = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: .command, timestamp: 0, windowNumber: 0, context: nil, characters: "+", charactersIgnoringModifiers: "+", isARepeat: false, keyCode: 24)!
        _ = controller.handleKeyDown(zoomInEvent)
        
        XCTAssertEqual(settings.zoomLevel, 1.1, accuracy: 0.01)
        
        // Act: Command - (keycode 27 is '-')
        let zoomOutEvent = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: .command, timestamp: 0, windowNumber: 0, context: nil, characters: "-", charactersIgnoringModifiers: "-", isARepeat: false, keyCode: 27)!
        _ = controller.handleKeyDown(zoomOutEvent)
        XCTAssertEqual(settings.zoomLevel, 1.0, accuracy: 0.01)
        
        // Act: Command 0 (keycode 29 is '0')
        let resetZoomEvent = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: .command, timestamp: 0, windowNumber: 0, context: nil, characters: "0", charactersIgnoringModifiers: "0", isARepeat: false, keyCode: 29)!
        settings.zoomLevel = 1.5
        _ = controller.handleKeyDown(resetZoomEvent)
        XCTAssertEqual(settings.zoomLevel, 1.0, accuracy: 0.01)
    }

    func testHandleKeyDown_DigitKeys_TriggersPaste() async throws {
        // Arrange: Add entries
        var entry = ClipboardEntry(timestamp: Date(), contentType: .text, plainTextContent: Data("Test".utf8))
        try repository.save(&entry)
        
        controller.togglePanel()
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Act: Command 1 (keycode 18 is '1')
        let digitEvent = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: .command, timestamp: 0, windowNumber: 0, context: nil, characters: "1", charactersIgnoringModifiers: "1", isARepeat: false, keyCode: 18)!
        _ = controller.handleKeyDown(digitEvent)
        
        // Wait for close
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertFalse(controller.isPanelVisible)
    }

    func testHandleKeyDown_DeleteKey_DeletesEntry() async throws {
        // Arrange: Add entry and select it
        var entry = ClipboardEntry(timestamp: Date(), contentType: .text, plainTextContent: Data("To Delete".utf8))
        try repository.save(&entry)
        
        // Wait for observation to pick up the new entry
        try await Task.sleep(nanoseconds: 100_000_000)
        
        viewModel.selectedIndex = 0
        
        controller.togglePanel()
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Act: Command + Backspace (keycode 51)
        let deleteEvent = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: .command, timestamp: 0, windowNumber: 0, context: nil, characters: "", charactersIgnoringModifiers: "", isARepeat: false, keyCode: 51)!
        _ = controller.handleKeyDown(deleteEvent)
        
        // Assert: Entry should be gone
        XCTAssertEqual(try repository.fetchAll().count, 0)
    }

    func testWindowDidResize_UpdatesSettings() {
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 400, height: 600), styleMask: [.resizable], backing: .buffered, defer: false)
        // We can't easily mock NSNotification in a way that triggers windowDidResize cleanly without setting delegate
        // But we can call the delegate method directly
        
        let initialWidth = SettingsManager.shared.panelWidth
        panel.setFrame(NSRect(x: 0, y: 0, width: 500, height: 700), display: true)
        
        controller.windowDidResize(Notification(name: NSWindow.didResizeNotification, object: panel))
        
        XCTAssertEqual(SettingsManager.shared.panelWidth, 500)
        XCTAssertEqual(SettingsManager.shared.panelHeight, 700)
        
        // Cleanup
        SettingsManager.shared.panelWidth = initialWidth
    }

    func testShowContextMenu() {
        // Direct call to ensure coverage
        controller.showContextMenu()
    }

    func testOpenSettings() {
        // We can't easily verify the action was sent to NSApp without mocking NSApp
        // but we can call it to ensure no crashes and coverage.
        // In a real app, this would show the settings window.
        // We use a private selector so we just call it.
        controller.openSettings()
    }

    // Note: We avoid calling quitApp() as it would terminate the test runner.
}
