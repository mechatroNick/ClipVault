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
        Settings {
            SettingsView()
        }
    }
}
