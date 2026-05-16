//
//  AppDelegate.swift
//  ClipVault
//
//  Created by ClipVault.
//

import AppKit
import SwiftUI

/// Manages the menu bar status item for ClipVault.
///
/// Creates an NSStatusItem with a template clipboard icon,
/// a left-click callback for the history panel, and a right-click
/// context menu with Settings and Quit.
final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Properties

    /// The menu bar status item. Exposed as internal for testing.
    private(set) var statusItem: NSStatusItem?

    /// Callback invoked on left-click. Stub for Phase 4 history panel integration.
    var onLeftClick: (() -> Void)?

    // MARK: - NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
    }

    // MARK: - Setup

    private func setupStatusItem() {
        guard statusItem == nil else { return }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem?.button else { return }

        // Template icon: monochrome, adapts to light/dark menu bar
        button.image = NSImage(
            systemSymbolName: "clipboard",
            accessibilityDescription: "ClipVault"
        )
        button.image?.isTemplate = true

        // Left-click action only — right-click shows NSMenu automatically via statusItem.menu
        button.action = #selector(handleLeftClick)
        button.target = self
        button.sendAction(on: [.leftMouseUp])

        // Right-click context menu
        let menu = NSMenu()
        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.keyEquivalentModifierMask = .command
        menu.addItem(settingsItem)
        menu.addItem(.separator())
        let quitItem = NSMenuItem(
            title: "Quit ClipVault",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.keyEquivalentModifierMask = .command
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    // MARK: - Actions

    @objc private func handleLeftClick() {
        onLeftClick?()
    }

    @objc private func openSettings() {
        NSApp.sendAction(Selector("showSettingsWindow:"), to: nil, from: nil)
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
