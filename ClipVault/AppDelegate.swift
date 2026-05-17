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

    private var menuBarController: MenuBarController?
    private var viewModel: ClipboardViewModel?
    private var captureService: ClipboardCaptureService?

    @MainActor
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Singleton enforcement: check if another instance is already running
        let bundleID = Bundle.main.bundleIdentifier!
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        
        if runningApps.count > 1 {
            // Found another instance. Focus it and terminate self.
            for app in runningApps where app != NSRunningApplication.current {
                app.activate(options: [.activateIgnoringOtherApps])
                break
            }
            NSApplication.shared.terminate(nil)
            return
        }

        let repository = ClipboardRepository()
        let vm = ClipboardViewModel(repository: repository)
        self.viewModel = vm
        
        let monitor = PasteboardMonitor()
        let capture = ClipboardCaptureService(monitor: monitor, repository: repository)
        self.captureService = capture
        
        let menuController = MenuBarController(viewModel: vm)
        self.menuBarController = menuController
        
        KeyboardHandler.shared.onHotKey = {
            menuController.togglePanel()
        }
        KeyboardHandler.shared.registerHotKey()
        
        Task {
            await capture.start()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        let capture = captureService
        let handler = KeyboardHandler.shared
        
        // Use a detached task or similar if we need to wait, but usually
        // for termination we just fire and hope for the best if we can't block.
        // Actually, we can't easily wait for async cleanup in applicationWillTerminate.
        // But we can at least signal stop.
        Task {
            await capture?.stop()
        }
        handler.unregisterHotKey()
    }
}
