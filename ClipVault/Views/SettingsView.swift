//
//  SettingsView.swift
//  ClipVault
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        TabView {
            GeneralSettingsView(settings: settings)
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            
            SecuritySettingsView()
                .tabItem {
                    Label("Security", systemImage: "lock.shield")
                }
            
            AboutSettingsView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 450, height: 300)
    }
}

struct GeneralSettingsView: View {
    @ObservedObject var settings: SettingsManager
    
    var body: some View {
        Form {
            Section(header: Text("History")) {
                Picker("Retention Period", selection: $settings.retentionDays) {
                    Text("1 Day").tag(1)
                    Text("3 Days").tag(3)
                    Text("7 Days").tag(7)
                    Text("30 Days").tag(30)
                    Text("Forever").tag(-1)
                }
                
                Stepper("Max Entries: \(settings.maxEntries)", value: $settings.maxEntries, in: 10...1000, step: 10)
            }
            
            Section(header: Text("Startup")) {
                Toggle("Launch at Login", isOn: $settings.launchAtLogin)
            }
            
            Section(header: Text("Vault")) {
                HStack {
                    Text("Vault Location")
                    Spacer()
                    Text(settings.vaultRootPath)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Button("Change...") {
                        changeVaultLocation()
                    }
                }
                
                HStack {
                    Text("Large File Threshold")
                    Spacer()
                    Slider(value: Binding(get: { Double(settings.largeFileThresholdMB) }, set: { settings.largeFileThresholdMB = Int($0) }), in: 1...100, step: 1)
                    Text("\(settings.largeFileThresholdMB) MB")
                        .frame(width: 50)
                }
            }
        }
        .padding()
    }
    
    private func changeVaultLocation() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                settings.vaultRootPath = url.path
            }
        }
    }
}

struct SecuritySettingsView: View {
    @StateObject private var settings = SettingsManager.shared
    @State private var newLabel = ""
    @State private var newPattern = ""
    
    var body: some View {
        Form {
            Section(header: Text("Encryption")) {
                HStack(spacing: 12) {
                    Image(systemName: "lock.shield")
                        .font(.title)
                        .foregroundColor(.accentColor)
                    VStack(alignment: .leading) {
                        Text("AES-256-GCM Active")
                            .font(.headline)
                        Text("All clipboard content is encrypted. Your keys are in the macOS Keychain.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section(header: Text("Redaction Rules (FTS Index)")) {
                Text("Built-in rules for Credit Cards, SSNs, and Secrets are always active.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(Array(settings.customPatterns.keys).sorted(), id: \.self) { label in
                    HStack {
                        Text(label)
                        Spacer()
                        Text(settings.customPatterns[label] ?? "")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                        Button(action: { settings.customPatterns.removeValue(forKey: label) }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                HStack {
                    TextField("Label", text: $newLabel)
                    TextField("Regex Pattern", text: $newPattern)
                    Button(action: addPattern) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                    }
                    .buttonStyle(.plain)
                    .disabled(newLabel.isEmpty || newPattern.isEmpty)
                }
            }
        }
        .padding()
    }
    
    private func addPattern() {
        // Validate regex
        if (try? NSRegularExpression(pattern: newPattern)) != nil {
            settings.customPatterns[newLabel] = newPattern
            newLabel = ""
            newPattern = ""
        }
    }
}

struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "clipboard")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
            
            Text("ClipVault")
                .font(.title)
            
            Text("Version 1.0.0 (MVP)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("© 2026 ClipVault Team")
                .font(.caption2)
        }
        .padding()
    }
}
