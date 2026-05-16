//
//  MenuBarLifecycleTests.swift
//  ClipVaultTests
//
//  Created by ClipVault.
//

import XCTest
@testable import ClipVault
import AppKit

final class MenuBarLifecycleTests: XCTestCase {

    private var appDelegate: AppDelegate!

    override func setUpWithError() throws {
        try super.setUpWithError()
        appDelegate = AppDelegate()
        appDelegate.applicationDidFinishLaunching(
            Notification(name: NSApplication.didFinishLaunchingNotification)
        )
    }

    override func tearDownWithError() throws {
        appDelegate = nil
        try super.tearDownWithError()
    }

    // MARK: - Status Item Creation

    func testAppDelegateCreatesStatusItem() {
        XCTAssertNotNil(appDelegate.statusItem, "Status item should be created on launch")
    }

    func testStatusItemHasVariableLength() throws {
        let statusItem = try XCTUnwrap(appDelegate.statusItem)
        XCTAssertEqual(
            statusItem.length,
            NSStatusItem.variableLength,
            "Status item should use variable length"
        )
    }

    func testStatusItemButtonExists() {
        XCTAssertNotNil(appDelegate.statusItem?.button, "Status item should have a button")
    }

    func testSetupStatusItemIsIdempotent() {
        // Calling applicationDidFinishLaunching again should NOT create a second status item
        // The idempotency guard prevents duplicate setup
        let originalItem = appDelegate.statusItem
        appDelegate.applicationDidFinishLaunching(
            Notification(name: NSApplication.didFinishLaunchingNotification)
        )
        XCTAssertTrue(
            appDelegate.statusItem === originalItem,
            "Second launch should reuse the existing status item (idempotent)"
        )
    }

    // MARK: - Template Icon

    func testStatusItemButtonHasTemplateImage() {
        let button = appDelegate.statusItem?.button
        XCTAssertNotNil(button?.image, "Button should have an image")
        XCTAssertTrue(
            button?.image?.isTemplate ?? false,
            "Button image should be configured as template"
        )
    }

    func testStatusItemButtonImageIsClipboardSymbol() {
        let button = appDelegate.statusItem?.button
        XCTAssertNotNil(button?.image, "Button should have an image")
        // Verify the image is the clipboard SF Symbol by checking accessibility description
        XCTAssertEqual(
            button?.image?.accessibilityDescription,
            "ClipVault",
            "Button image should be the clipboard SF Symbol with ClipVault description"
        )
    }

    // MARK: - Right-Click Context Menu

    func testRightClickMenuExists() {
        XCTAssertNotNil(appDelegate.statusItem?.menu, "Right-click menu should be set")
    }

    func testRightClickMenuHasThreeItems() {
        let menu = appDelegate.statusItem?.menu
        XCTAssertEqual(menu?.items.count, 3, "Menu should have 3 items: Settings, separator, Quit")
    }

    func testRightClickMenuHasSettingsItem() {
        let menu = appDelegate.statusItem?.menu
        let settingsItem = menu?.item(withTitle: "Settings...")
        XCTAssertNotNil(settingsItem, "Menu should have a Settings... item")
        XCTAssertNotNil(settingsItem?.action, "Settings item should have an action")
        XCTAssertEqual(settingsItem?.keyEquivalent, ",", "Settings should use ⌘, shortcut")
        XCTAssertEqual(
            settingsItem?.keyEquivalentModifierMask,
            .command,
            "Settings shortcut should use Command modifier"
        )
    }

    func testRightClickMenuHasQuitItem() {
        let menu = appDelegate.statusItem?.menu
        let quitItem = menu?.item(withTitle: "Quit ClipVault")
        XCTAssertNotNil(quitItem, "Menu should have a Quit ClipVault item")
        XCTAssertNotNil(quitItem?.action, "Quit item should have an action")
        XCTAssertEqual(quitItem?.keyEquivalent, "q", "Quit should use ⌘Q shortcut")
        XCTAssertEqual(
            quitItem?.keyEquivalentModifierMask,
            .command,
            "Quit shortcut should use Command modifier"
        )
    }

    func testRightClickMenuHasSeparatorBetweenItems() {
        let menu = appDelegate.statusItem?.menu
        let separatorIndex = menu?.items.firstIndex { $0.isSeparatorItem }
        XCTAssertEqual(separatorIndex, 1, "Separator should be between Settings and Quit (index 1)")
    }

    // MARK: - Left-Click Action

    func testLeftClickCallbackIsInvoked() {
        let expectation = self.expectation(description: "Left-click callback invoked")
        appDelegate.onLeftClick = {
            expectation.fulfill()
        }
        // Simulate button action
        _ = appDelegate.statusItem?.button?.target?
            .perform(appDelegate.statusItem?.button?.action, with: nil)
        wait(for: [expectation], timeout: 1.0)
    }

    func testLeftClickCallbackIsNilByDefault() {
        XCTAssertNil(appDelegate.onLeftClick, "Left-click callback should be nil by default (stub)")
    }

    // MARK: - Left-Click with Nil Callback

    func testHandleLeftClickWhenCallbackIsNilDoesNotCrash() {
        // Verify nil callback is handled gracefully (no crash)
        appDelegate.onLeftClick = nil
        _ = appDelegate.statusItem?.button?.target?
            .perform(appDelegate.statusItem?.button?.action, with: nil)
        // If we reach here without crashing, the test passes implicitly
    }

    // MARK: - Open Settings Action

    func testOpenSettingsMenuItemHasShowSettingsWindowAction() {
        let menu = appDelegate.statusItem?.menu
        let settingsItem = menu?.item(withTitle: "Settings...")
        guard let action = settingsItem?.action else {
            XCTFail("Settings menu item should have an action")
            return
        }
        // When target is nil, action traverses responder chain — verify action is set
        let actionName = NSStringFromSelector(action)
        XCTAssertEqual(actionName, "openSettings", "Settings should invoke openSettings selector")
    }

    // MARK: - Quit Action Wiring

    func testQuitMenuItemHasQuitAppAction() {
        let menu = appDelegate.statusItem?.menu
        let quitItem = menu?.item(withTitle: "Quit ClipVault")
        guard let action = quitItem?.action else {
            XCTFail("Quit menu item should have an action")
            return
        }
        // When target is nil, action traverses responder chain — verify action is set
        let actionName = NSStringFromSelector(action)
        XCTAssertEqual(actionName, "quitApp", "Quit should invoke quitApp selector")
    }

    // MARK: - Button Configuration

    func testStatusItemButtonTargetIsAppDelegate() {
        let button = appDelegate.statusItem?.button
        XCTAssertTrue(
            button?.target === appDelegate,
            "Button target should be the AppDelegate instance"
        )
    }

    // MARK: - Open Settings Direct Invocation

    func testOpenSettingsActionCanBeInvokedWithoutCrash() {
        // Call the openSettings selector directly — harmless in test environment
        let settingsSelector = Selector("openSettings")
        guard appDelegate.responds(to: settingsSelector) else {
            XCTFail("AppDelegate should respond to openSettings")
            return
        }
        _ = appDelegate.perform(settingsSelector)
        // If we reach here without crashing, the method body is exercised — test passes implicitly
    }

    func testStatusItemButtonHasActionAndTarget() {
        guard let button = appDelegate.statusItem?.button else {
            XCTFail("Button should exist")
            return
        }
        XCTAssertNotNil(button.action, "Button should have an action wired for left-click")
        XCTAssertNotNil(button.target, "Button should have a target wired")
    }

    func testRightClickUsesMenuNotButtonAction() {
        guard let button = appDelegate.statusItem?.button else {
            XCTFail("Button should exist")
            return
        }
        // The right-click context menu is set on the statusItem, not via button action
        XCTAssertNotNil(appDelegate.statusItem?.menu, "Right-click should show context menu")
        // Button should have action (for left-click) but is irrelevant for right-click
        XCTAssertNotNil(button.action, "Button action should exist for left-click")
    }

    // MARK: - LSUIElement / Dock Icon Behavior

    func testActivationPolicyIsAccessory() {
        // LSUIElement = YES maps to .accessory activation policy
        let policy = NSApp.activationPolicy()
        XCTAssertTrue(
            policy == .accessory || policy == .prohibited,
            "App should use accessory or prohibited activation policy (no dock icon). Actual: \(policy.rawValue)"
        )
    }
}
