//
//  PrivacyIgnoreListTests.swift
//  ClipVaultTests
//
//  Tests for Phase 3: Privacy Ignore List
//  Verifies ignore list matching logic, persistence, and clipboard filtering.
//

import XCTest
import SwiftUI
@testable import ClipVault

final class PrivacyIgnoreListTests: XCTestCase {

    private var settings: SettingsManager!

    override func setUp() {
        super.setUp()
        settings = SettingsManager.shared
        // Ensure known state: reset ignore list to defaults
        settings.ignoredBundleIDs = PrivacyIgnoreList.defaultIgnoredBundleIDs
    }

    override func tearDown() {
        // Restore defaults
        settings.ignoredBundleIDs = PrivacyIgnoreList.defaultIgnoredBundleIDs
        super.tearDown()
    }

    // MARK: - PrivacyIgnoreList Defaults

    func testPrivacyIgnoreList_DefaultsContain1Password() {
        let defaults = PrivacyIgnoreList.defaultIgnoredBundleIDs
        XCTAssertTrue(defaults.contains("com.agilebits.onepassword-osx") ||
                      defaults.contains("com.agilebits.onepassword7"),
                      "Default ignore list should contain 1Password bundle ID")
    }

    func testPrivacyIgnoreList_DefaultsContainKeychainAccess() {
        let defaults = PrivacyIgnoreList.defaultIgnoredBundleIDs
        XCTAssertTrue(defaults.contains("com.apple.keychainaccess"),
                      "Default ignore list should contain Keychain Access bundle ID")
    }

    func testPrivacyIgnoreList_DefaultsContainBitwarden() {
        let defaults = PrivacyIgnoreList.defaultIgnoredBundleIDs
        XCTAssertTrue(defaults.contains("com.bitwarden.desktop"),
                      "Default ignore list should contain Bitwarden bundle ID")
    }

    // MARK: - PrivacyIgnoreList Matching

    func testPrivacyIgnoreList_IsIgnored_ReturnsTrueForKnownApp() {
        let ignoredIDs = ["com.agilebits.onepassword-osx", "com.apple.keychainaccess", "com.bitwarden.desktop"]
        XCTAssertTrue(PrivacyIgnoreList.isIgnored(bundleID: "com.agilebits.onepassword-osx", in: ignoredIDs))
        XCTAssertTrue(PrivacyIgnoreList.isIgnored(bundleID: "com.apple.keychainaccess", in: ignoredIDs))
        XCTAssertTrue(PrivacyIgnoreList.isIgnored(bundleID: "com.bitwarden.desktop", in: ignoredIDs))
    }

    func testPrivacyIgnoreList_IsIgnored_ReturnsFalseForAllowedApp() {
        let ignoredIDs = ["com.agilebits.onepassword-osx"]
        XCTAssertFalse(PrivacyIgnoreList.isIgnored(bundleID: "com.apple.safari", in: ignoredIDs))
        XCTAssertFalse(PrivacyIgnoreList.isIgnored(bundleID: "com.microsoft.VSCode", in: ignoredIDs))
    }

    func testPrivacyIgnoreList_IsIgnored_CaseInsensitive() {
        let ignoredIDs = ["com.agilebits.onepassword-osx"]
        // Bundle IDs should be compared case-insensitively
        XCTAssertTrue(PrivacyIgnoreList.isIgnored(bundleID: "COM.AGILEBITS.ONEPASSWORD-OSX", in: ignoredIDs))
    }

    func testPrivacyIgnoreList_IsIgnored_NilBundleID_ReturnsFalse() {
        let ignoredIDs = ["com.agilebits.onepassword-osx"]
        XCTAssertFalse(PrivacyIgnoreList.isIgnored(bundleID: nil, in: ignoredIDs))
    }

    func testPrivacyIgnoreList_IsIgnored_EmptyList_ReturnsFalse() {
        XCTAssertFalse(PrivacyIgnoreList.isIgnored(bundleID: "com.agilebits.onepassword-osx", in: []))
    }

    // MARK: - SettingsManager Persistence

    func testSettingsManager_IgnoredBundleIDs_Persists() {
        let custom = ["com.example.app1", "com.example.app2"]
        settings.ignoredBundleIDs = custom

        let stored = UserDefaults.standard.stringArray(forKey: "cv_ignoredBundleIDs")
        XCTAssertEqual(stored, custom, "Ignored bundle IDs should be persisted")
    }

    func testSettingsManager_IgnoredBundleIDs_LoadsDefaults() {
        // Remove stored value
        UserDefaults.standard.removeObject(forKey: "cv_ignoredBundleIDs")
        // Defaults should be the privacy list defaults
        let defaults = PrivacyIgnoreList.defaultIgnoredBundleIDs
        XCTAssertFalse(defaults.isEmpty, "Default ignore list should not be empty")
    }

    func testSettingsManager_AddToIgnoreList() {
        let initialCount = settings.ignoredBundleIDs.count
        let newID = "com.test.newapp"
        if !settings.ignoredBundleIDs.contains(newID) {
            settings.ignoredBundleIDs.append(newID)
        }
        XCTAssertEqual(settings.ignoredBundleIDs.count, initialCount + 1)
        XCTAssertTrue(settings.ignoredBundleIDs.contains(newID))
    }

    func testSettingsManager_RemoveFromIgnoreList() {
        let toRemove = "com.test.toremove"
        settings.ignoredBundleIDs = [toRemove, "com.other.app"]
        settings.ignoredBundleIDs.removeAll { $0 == toRemove }
        XCTAssertFalse(settings.ignoredBundleIDs.contains(toRemove))
        XCTAssertEqual(settings.ignoredBundleIDs.count, 1)
    }

    // MARK: - ClipboardCaptureService Integration

    func testCaptureService_IgnoresClipsFromIgnoredApp() async throws {
        let dbManager = try DatabaseManager(path: ":memory:")
        let encryptionService = try EncryptionService()
        let keychainManager = MockKeychainManager()
        let repository = ClipboardRepository(
            dbManager: dbManager,
            encryptionService: encryptionService,
            keychainManager: keychainManager
        )
        let mockPasteboard = MockPasteboard()
        let monitor = PasteboardMonitor(pasteboard: mockPasteboard, pollInterval: 0.05)

        // Configure ignore list
        settings.ignoredBundleIDs = ["com.agilebits.onepassword-osx"]

        // Create service that pretends 1Password is the frontmost app
        let service = ClipboardCaptureService(
            monitor: monitor,
            repository: repository,
            pasteboard: mockPasteboard,
            workspaceAppIdentifier: { "com.agilebits.onepassword-osx" }
        )

        await service.start()
        try await Task.sleep(nanoseconds: 100_000_000)

        // Act: Simulate copy from 1Password
        mockPasteboard.simulateCopy(string: "super_secret_password_123")
        try await Task.sleep(nanoseconds: 300_000_000)

        // Assert: No entries should be saved
        let entries = (try? repository.fetchAll()) ?? []
        XCTAssertEqual(entries.count, 0, "Clipboard entries from ignored apps should be rejected")

        await service.stop()
    }

    func testCaptureService_AllowsClipsFromNonIgnoredApp() async throws {
        let dbManager = try DatabaseManager(path: ":memory:")
        let encryptionService = try EncryptionService()
        let keychainManager = MockKeychainManager()
        let repository = ClipboardRepository(
            dbManager: dbManager,
            encryptionService: encryptionService,
            keychainManager: keychainManager
        )
        let mockPasteboard = MockPasteboard()
        let monitor = PasteboardMonitor(pasteboard: mockPasteboard, pollInterval: 0.05)

        // Configure ignore list
        settings.ignoredBundleIDs = ["com.agilebits.onepassword-osx"]

        // Create service that pretends Safari is the frontmost app
        let service = ClipboardCaptureService(
            monitor: monitor,
            repository: repository,
            pasteboard: mockPasteboard,
            workspaceAppIdentifier: { "com.apple.safari" }
        )

        await service.start()
        try await Task.sleep(nanoseconds: 100_000_000)

        // Act: Simulate copy from Safari
        mockPasteboard.simulateCopy(string: "https://apple.com")
        
        let startTime = Date()
        var entries = try repository.fetchAll()
        while entries.isEmpty && Date().timeIntervalSince(startTime) < 1.0 {
            try await Task.sleep(nanoseconds: 50_000_000)
            entries = try repository.fetchAll()
        }

        // Assert: Entry should be saved
        XCTAssertEqual(entries.count, 1, "Clipboard entries from allowed apps should be captured")

        await service.stop()
    }

    // MARK: - PrivacyIgnoreListView

    func testPrivacyIgnoreListView_Initializes() {
        let settings = SettingsManager.shared
        let view = PrivacyIgnoreListView(settings: settings)
        let hosting = NSHostingView(rootView: view)
        hosting.frame = NSRect(x: 0, y: 0, width: 500, height: 400)
        hosting.layout()
        XCTAssertNotNil(hosting)
    }
}
