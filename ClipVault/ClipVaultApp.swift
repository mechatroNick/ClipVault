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
    // MARK: - Instance Properties

    // MARK: - Body

    var body: some Scene {
        // MARK: Menu Bar Extra (primary UI)
        MenuBarExtra("ClipVault", systemImage: "clipboard") {
            // Placeholder text — replaced in Phase 4 with history panel
            Text("ClipVault")
                .font(.headline)
            Divider()
            Button("Settings...") {
                openSettings()
            }
            .keyboardShortcut(",", modifiers: .command)
            Divider()
            Button("Quit ClipVault") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }

        // MARK: Settings Window (FR10)
        Settings {
            SettingsView()
        }
    }

    // MARK: - Private Methods

    /// Opens the Settings window programmatically.
    private func openSettings() {
        NSApp.sendAction(Selector("showSettingsWindow:"), to: nil, from: nil)
    }
}

// MARK: - SettingsView

/// Placeholder settings view (FR10). Replaced with full implementation in Phase 5.
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
