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
}
