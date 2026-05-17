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
    private var keychainManager: KeychainManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        dbManager = try DatabaseManager(path: ":memory:")
        encryptionService = try EncryptionService()
        keychainManager = KeychainManager(service: "com.clipvault.test.menubar.\(UUID().uuidString)")
        repository = ClipboardRepository(
            dbManager: dbManager,
            encryptionService: encryptionService,
            keychainManager: keychainManager
        )
        viewModel = ClipboardViewModel(repository: repository)
        controller = MenuBarController(viewModel: viewModel)
    }
    
    override func tearDownWithError() throws {
        try? keychainManager.deleteKey()
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
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Assert: Panel should be visible
        XCTAssertTrue(controller.isPanelVisible)
        
        // Act: Close
        controller.togglePanel()
        
        // Wait for close animation
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Assert: Panel should be hidden
        XCTAssertFalse(controller.isPanelVisible)
    }
    
    func testArrowNavigation_UpdatesViewModelSelection() async throws {
        // Arrange: Add some entries
        var entry1 = ClipboardEntry(timestamp: Date(), contentType: "text", plainTextContent: Data("1".utf8))
        var entry2 = ClipboardEntry(timestamp: Date().addingTimeInterval(1), contentType: "text", plainTextContent: Data("2".utf8))
        try repository.save(&entry1)
        try repository.save(&entry2)
        
        // Open panel
        controller.togglePanel()
        try await Task.sleep(nanoseconds: 200_000_000)
        
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
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertTrue(controller.isPanelVisible)
        
        // Act: Escape (keycode 53)
        let escapeEvent = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: 0, context: nil, characters: "", charactersIgnoringModifiers: "", isARepeat: false, keyCode: 53)!
        _ = controller.handleKeyDown(escapeEvent)
        
        // Wait for close animation
        try await Task.sleep(nanoseconds: 300_000_000)
        
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
}
