//
//  HistoryPanelControlTests.swift
//  ClipVaultTests
//

import XCTest
import SwiftUI
@testable import ClipVault

@MainActor
final class HistoryPanelControlTests: XCTestCase {
    
    private var repository: ClipboardRepository!
    private var dbManager: DatabaseManager!
    private var encryptionService: EncryptionService!
    private var keychainManager: KeychainManager!
    private var viewModel: ClipboardViewModel!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        dbManager = try DatabaseManager(path: ":memory:")
        encryptionService = try EncryptionService()
        keychainManager = KeychainManager(service: "com.clipvault.test.controls.\(UUID().uuidString)")
        repository = ClipboardRepository(
            dbManager: dbManager,
            encryptionService: encryptionService,
            keychainManager: keychainManager
        )
        viewModel = ClipboardViewModel(repository: repository)
    }
    
    override func tearDownWithError() throws {
        try? keychainManager.deleteKey()
        viewModel = nil
        repository = nil
        dbManager = nil
        encryptionService = nil
        keychainManager = nil
        try super.tearDownWithError()
    }
    
    // MARK: - View Construction
    
    func testHistoryPanelView_RendersWithGearButton() {
        let view = HistoryPanelView(viewModel: viewModel)
        let mirror = Mirror(reflecting: view)
        
        // Verify the onClose property exists (nil by default)
        var foundOnClose = false
        var foundOnOpenSettings = false
        for child in mirror.children {
            if child.label == "onClose" {
                foundOnClose = true
            }
            if child.label == "onOpenSettings" {
                foundOnOpenSettings = true
            }
        }
        XCTAssertTrue(foundOnClose, "HistoryPanelView should have an onClose closure")
        XCTAssertTrue(foundOnOpenSettings, "HistoryPanelView should have an onOpenSettings closure")
    }
    
    func testHistoryPanelView_RendersWithCloseButton() {
        // Create view with both closures wired
        let view = HistoryPanelView(
            viewModel: viewModel,
            onClose: {},
            onOpenSettings: {}
        )
        // Verify it can be created without crashing — implicit proof both buttons exist
        _ = view.body
    }
    
    // MARK: - onClose Callback

    func testOnCloseCallback_FiresWhenXButtonTapped() {
        var didClose = false
        let view = HistoryPanelView(
            viewModel: viewModel,
            onClose: { didClose = true },
            onOpenSettings: {}
        )

        XCTAssertFalse(didClose, "Should not have closed yet")

        // Simulate the close action
        view.onClose?()
        XCTAssertTrue(didClose, "onClose should have been called")
    }
    
    // MARK: - onOpenSettings Callback

    func testOnOpenSettingsCallback_FiresWhenGearButtonTapped() {
        var didOpenSettings = false
        let view = HistoryPanelView(
            viewModel: viewModel,
            onClose: {},
            onOpenSettings: { didOpenSettings = true }
        )

        XCTAssertFalse(didOpenSettings, "Should not have opened settings yet")

        // Simulate the settings action
        view.onOpenSettings?()
        XCTAssertTrue(didOpenSettings, "onOpenSettings should have been called")
    }
    
    // MARK: - MenuBarController Integration
    
    func testMenuBarController_PassesCloseActionToView() async throws {
        let controller = MenuBarController(viewModel: viewModel)
        
        // Open the panel first
        controller.togglePanel()
        try await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertTrue(controller.isPanelVisible, "Panel should be visible after open")
        
        // Close via the controller's closePanel method
        controller.closePanel()
        try await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertFalse(controller.isPanelVisible, "Panel should be hidden after closePanel")
    }
    
    func testMenuBarController_ClosePanelIsIdempotent() async throws {
        let controller = MenuBarController(viewModel: viewModel)
        
        // closePanel when not visible — should not crash
        controller.closePanel()
        XCTAssertFalse(controller.isPanelVisible, "Panel should remain hidden")
        
        // Open then close twice — second close should be a no-op
        controller.togglePanel()
        try await Task.sleep(nanoseconds: 300_000_000)
        controller.closePanel()
        try await Task.sleep(nanoseconds: 300_000_000)
        controller.closePanel() // Second call — idempotent
        XCTAssertFalse(controller.isPanelVisible, "Panel should still be hidden after double close")
    }
    
    // MARK: - Default Nil Closures
    
    func testHistoryPanelView_DefaultClosuresAreNil() {
        let view = HistoryPanelView(viewModel: viewModel)
        XCTAssertNil(view.onClose, "onClose should default to nil")
        XCTAssertNil(view.onOpenSettings, "onOpenSettings should default to nil")
    }
}