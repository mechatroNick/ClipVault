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
}
