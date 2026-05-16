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

// MARK: - SettingsView

/// Placeholder settings view. Replaced with full implementation in Phase 5.
private struct SettingsView: View {
    var body: some View {
        TabView {
            Text("General settings will appear here.")
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            Text("Security settings will appear here.")
                .tabItem {
                    Label("Security", systemImage: "lock.shield")
                }
            Text("About ClipVault")
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 450, height: 300)
    }
}
