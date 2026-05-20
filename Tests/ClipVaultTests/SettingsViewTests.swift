//
//  SettingsViewTests.swift
//  ClipVaultTests
//

import XCTest
import SwiftUI
@testable import ClipVault

final class SettingsViewTests: XCTestCase {
    func testSettingsView_Initializes() {
        let view = SettingsView()
        let hosting = NSHostingView(rootView: view)
        hosting.frame = NSRect(x: 0, y: 0, width: 500, height: 400)
        hosting.layout()
        XCTAssertNotNil(hosting)
    }
    
    func testGeneralSettingsView_Initializes() {
        let settings = SettingsManager.shared
        let view = GeneralSettingsView(settings: settings)
        let hosting = NSHostingView(rootView: view)
        hosting.frame = NSRect(x: 0, y: 0, width: 500, height: 400)
        hosting.layout()
        XCTAssertNotNil(hosting)
    }
    
    func testSecuritySettingsView_Initializes() {
        let settings = SettingsManager.shared
        let view = SecuritySettingsView(settings: settings)
        let hosting = NSHostingView(rootView: view)
        hosting.frame = NSRect(x: 0, y: 0, width: 500, height: 400)
        hosting.layout()
        XCTAssertNotNil(hosting)
    }
    
    func testAboutSettingsView_Initializes() {
        let view = AboutSettingsView()
        let hosting = NSHostingView(rootView: view)
        hosting.frame = NSRect(x: 0, y: 0, width: 500, height: 400)
        hosting.layout()
        XCTAssertNotNil(hosting)
    }
}
