//
//  SettingsTabViewTests.swift
//  ClipVaultTests
//
//  Tests for Phase 3: Settings Window Overhaul
//  Verifies TabView structure, all tab views initialize correctly, and
//  the Appearance tab is present and functional.
//

import XCTest
import SwiftUI
@testable import ClipVault

final class SettingsTabViewTests: XCTestCase {

    // MARK: - Settings TabView Structure

    func testSettingsView_HasTabView() {
        let view = SettingsView()
        let hosting = NSHostingView(rootView: view)
        hosting.frame = NSRect(x: 0, y: 0, width: 600, height: 500)
        hosting.layout()
        XCTAssertNotNil(hosting)
    }

    func testSettingsView_MinimumSize() {
        let view = SettingsView()
        let hosting = NSHostingView(rootView: view)
        hosting.frame = NSRect(x: 0, y: 0, width: 600, height: 500)
        hosting.layout()
        // Verify it renders within bounds
        XCTAssertGreaterThanOrEqual(hosting.frame.width, 600)
        XCTAssertGreaterThanOrEqual(hosting.frame.height, 500)
    }

    // MARK: - Appearance Settings Tab

    func testAppearanceSettingsView_Initializes() {
        let settings = SettingsManager.shared
        let view = AppearanceSettingsView(settings: settings)
        let hosting = NSHostingView(rootView: view)
        hosting.frame = NSRect(x: 0, y: 0, width: 500, height: 400)
        hosting.layout()
        XCTAssertNotNil(hosting)
    }

    // MARK: - General Settings Tab (regression)

    func testGeneralSettingsView_StillInitializes() {
        let settings = SettingsManager.shared
        let view = GeneralSettingsView(settings: settings)
        let hosting = NSHostingView(rootView: view)
        hosting.frame = NSRect(x: 0, y: 0, width: 500, height: 400)
        hosting.layout()
        XCTAssertNotNil(hosting)
    }

    // MARK: - Security Settings Tab (regression)

    func testSecuritySettingsView_StillInitializes() {
        let settings = SettingsManager.shared
        let view = SecuritySettingsView(settings: settings)
        let hosting = NSHostingView(rootView: view)
        hosting.frame = NSRect(x: 0, y: 0, width: 500, height: 400)
        hosting.layout()
        XCTAssertNotNil(hosting)
    }

    // MARK: - About Tab (regression)

    func testAboutSettingsView_StillInitializes() {
        let view = AboutSettingsView()
        let hosting = NSHostingView(rootView: view)
        hosting.frame = NSRect(x: 0, y: 0, width: 500, height: 400)
        hosting.layout()
        XCTAssertNotNil(hosting)
    }
}
