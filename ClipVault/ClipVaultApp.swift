//
//  ClipVaultApp.swift
//  ClipVault
//
//  Created by ClipVault.
//

import SwiftUI

/// The entry point for ClipVault, a menu bar-only clipboard manager.
///
/// ClipVault monitors the system pasteboard, stores encrypted clipboard history,
/// and provides quick access via a menu bar panel. It has no dock icon
/// (LSUIElement = YES in Info.plist) and operates entirely from the menu bar.
@main
struct ClipVaultApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // We manage the status item and windows manually via AppDelegate and MenuBarController.
        // We use an empty Settings scene here just to satisfy the SwiftUI App requirements
        // without creating any additional UI or status bar icons.
        Settings {
            EmptyView()
        }
        .commands {
            // Remove the default Settings command so it doesn't swallow Cmd+,
            // allowing the MenuBarController's local event monitor to handle it.
            CommandGroup(replacing: .appSettings) { }
        }
    }
}
