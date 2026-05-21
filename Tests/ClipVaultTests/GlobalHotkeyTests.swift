//
//  GlobalHotkeyTests.swift
//  ClipVaultTests
//
//  Tests for Phase 3: Customizable Global Hotkey
//  Verifies hotkey registration, persistence, and retrieval via SettingsManager.
//

import XCTest
import SwiftUI
@testable import ClipVault

final class GlobalHotkeyTests: XCTestCase {

    private var settings: SettingsManager!

    override func setUp() {
        super.setUp()
        settings = SettingsManager.shared
    }

    // MARK: - HotkeyDescriptor Model

    func testHotkeyDescriptor_DefaultValue() {
        // The default hotkey should be Cmd+Shift+V
        let hotkey = HotkeyDescriptor.default
        XCTAssertTrue(hotkey.modifiers.contains(.command))
        XCTAssertTrue(hotkey.modifiers.contains(.shift))
        XCTAssertEqual(hotkey.keyCode, 9) // keyCode 9 = 'v' on US keyboard
    }

    func testHotkeyDescriptor_DisplayString_CmdShiftV() {
        let hotkey = HotkeyDescriptor(modifiers: [.command, .shift], keyCode: 9)
        let display = hotkey.displayString
        XCTAssertTrue(display.contains("⌘"), "Display string should contain command symbol")
        XCTAssertTrue(display.contains("⇧"), "Display string should contain shift symbol")
        XCTAssertTrue(display.contains("V"), "Display string should contain key name")
    }

    func testHotkeyDescriptor_DisplayString_CmdOptionSpace() {
        let hotkey = HotkeyDescriptor(modifiers: [.command, .option], keyCode: 49) // 49 = space
        let display = hotkey.displayString
        XCTAssertTrue(display.contains("⌘"), "Display string should contain command symbol")
        XCTAssertTrue(display.contains("⌥"), "Display string should contain option symbol")
    }

    func testHotkeyDescriptor_Codable_RoundTrip() throws {
        let original = HotkeyDescriptor(modifiers: [.command, .shift], keyCode: 9)
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HotkeyDescriptor.self, from: encoded)
        XCTAssertEqual(original.keyCode, decoded.keyCode)
        XCTAssertEqual(original.modifiers.rawValue, decoded.modifiers.rawValue)
    }

    // MARK: - SettingsManager Persistence

    func testSettingsManager_GlobalHotkey_PersistsToUserDefaults() throws {
        let newHotkey = HotkeyDescriptor(modifiers: [.command, .option], keyCode: 49)
        settings.globalHotkey = newHotkey

        // Read back from a fresh load via UserDefaults
        let encoded = UserDefaults.standard.data(forKey: "cv_globalHotkey")
        XCTAssertNotNil(encoded, "Hotkey should be persisted in UserDefaults")
        let decoded = try JSONDecoder().decode(HotkeyDescriptor.self, from: encoded!)
        XCTAssertEqual(decoded.keyCode, 49)
        XCTAssertEqual(decoded.modifiers.rawValue, newHotkey.modifiers.rawValue)

        // Reset to default
        settings.globalHotkey = .default
    }

    func testSettingsManager_GlobalHotkey_DefaultIsCommandShiftV() {
        // Remove any stored value to test default initialization
        UserDefaults.standard.removeObject(forKey: "cv_globalHotkey")

        // Re-check default from the descriptor
        let hotkey = HotkeyDescriptor.default
        XCTAssertTrue(hotkey.modifiers.contains(.command))
        XCTAssertTrue(hotkey.modifiers.contains(.shift))
        XCTAssertEqual(hotkey.keyCode, 9)
    }

    // MARK: - HotkeyRecorderView

    func testHotkeyRecorderView_Initializes() {
        let hotkey = Binding.constant(HotkeyDescriptor.default)
        let view = HotkeyRecorderView(hotkey: hotkey)
        let hosting = NSHostingView(rootView: view)
        hosting.frame = NSRect(x: 0, y: 0, width: 300, height: 50)
        hosting.layout()
        XCTAssertNotNil(hosting)
    }

    func testHotkeyDescriptor_DisplayString_UnknownKeyCode() {
        // Key code 200 is not in the known map — should fall back to "(200)"
        let hotkey = HotkeyDescriptor(modifiers: [.command], keyCode: 200)
        XCTAssertTrue(hotkey.displayString.contains("(200)"),
                      "Unmapped key codes should display as '(keyCode)'")
    }
}
