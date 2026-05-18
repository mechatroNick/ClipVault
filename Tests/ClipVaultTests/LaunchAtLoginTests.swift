//
//  LaunchAtLoginTests.swift
//  ClipVaultTests
//

import XCTest
import ServiceManagement
@testable import ClipVault

final class LaunchAtLoginTests: XCTestCase {

    override func setUp() {
        // Clean up: unregister to start fresh
        try? SMAppService.mainApp.unregister()
        SettingsManager.shared.launchAtLogin = false
    }

    override func tearDown() {
        // Clean up: unregister after test
        try? SMAppService.mainApp.unregister()
        UserDefaults.standard.removeObject(forKey: "cv_launchAtLogin")
    }

    func testLaunchAtLogin_SyncsWithSystemStatus() {
        let settings = SettingsManager.shared
        // The initial value should reflect the actual SMAppService status
        let expectedStatus = SMAppService.mainApp.status == .enabled
        XCTAssertEqual(settings.launchAtLogin, expectedStatus,
                       "launchAtLogin should match SMAppService.mainApp.status on init")
    }

    func testLaunchAtLogin_SettingToTrueRegistersService() {
        let settings = SettingsManager.shared
        settings.launchAtLogin = true
        // In a test environment, registration may fail due to code signing;
        // verify that the property attempted to register and the state is consistent
        let currentStatus = SMAppService.mainApp.status
        if currentStatus == .enabled {
            XCTAssertTrue(settings.launchAtLogin)
        } else {
            // If registration failed (test env not code-signed), the didSet
            // should have reverted to match reality
            XCTAssertEqual(settings.launchAtLogin, false)
        }
    }

    func testLaunchAtLogin_SettingToFalseUnregistersService() {
        let settings = SettingsManager.shared
        settings.launchAtLogin = false
        // didSet reverts to match reality on failure; both property and UserDefaults should align
        let actual = SMAppService.mainApp.status == .enabled
        XCTAssertEqual(settings.launchAtLogin, actual)
        XCTAssertEqual(UserDefaults.standard.bool(forKey: "cv_launchAtLogin"), actual)
    }

    func testLaunchAtLogin_PersistsToUserDefaults() {
        let settings = SettingsManager.shared

        // Save the original state to restore later
        let originalStatus = SMAppService.mainApp.status
        let originallyEnabled = originalStatus == .enabled
        if originallyEnabled {
            try? SMAppService.mainApp.unregister()
        }

        // Test: after a successful enable, UserDefaults should reflect it
        settings.launchAtLogin = true
        if SMAppService.mainApp.status == .enabled {
            XCTAssertTrue(settings.launchAtLogin)
            XCTAssertTrue(UserDefaults.standard.bool(forKey: "cv_launchAtLogin"))
        }
        // When registration fails (test env), didSet reverts both to match system state (false)

        // Test: after a successful disable, UserDefaults should reflect it
        settings.launchAtLogin = false
        XCTAssertFalse(settings.launchAtLogin)
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "cv_launchAtLogin"))

        // Restore original state
        if originallyEnabled {
            try? SMAppService.mainApp.register()
        }
    }

    func testLaunchAtLogin_ErrorHandlingRevertsState() {
        // This test verifies that if SMAppService operations fail,
        // the property reverts to the actual system state
        let settings = SettingsManager.shared

        // Force an inconsistent state: try to register (may fail in test env)
        settings.launchAtLogin = true

        // After didSet completes, launchAtLogin should match reality
        let actualStatus = SMAppService.mainApp.status == .enabled
        XCTAssertEqual(settings.launchAtLogin, actualStatus,
                       "After error handling, launchAtLogin should match actual system status")
    }
}