//
//  SettingsView.swift
//  ClipVault
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            TabView {
                GeneralSettingsView(settings: settings)
                    .tabItem {
                        Label("General", systemImage: "gearshape")
                    }
                
                SecuritySettingsView(settings: settings)
                    .tabItem {
                        Label("Security", systemImage: "lock.shield")
                    }
                
                AboutSettingsView()
                    .tabItem {
                        Label("About", systemImage: "info.circle")
                    }
            }
            
            Divider()
            
            HStack {
                Spacer()
                Button("Save & Close") {
                    // Settings are already saved via didSet in SettingsManager
                    NSApp.keyWindow?.close()
                }
                .keyboardShortcut(.defaultAction)
                .padding()
            }
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 500, height: 400)
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
                }
                
                Stepper("Max Entries: \(settings.maxEntries)", value: $settings.maxEntries, in: 10...1000, step: 10)

                HStack {
                    Text("UI Zoom Level")
                    Slider(value: $settings.zoomLevel, in: 0.5...2.0, step: 0.1)
                    Text(String(format: "%.1fx", settings.zoomLevel))
                        .frame(width: 40)
                }
            }
            
            Section(header: Text("Startup")) {
                Toggle("Launch at Login", isOn: $settings.launchAtLogin)
            }
            
            Section(header: Text("Vault & Storage")) {
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
                    Slider(value: Binding(get: { Double(settings.largeFileThresholdMB) }, set: { settings.largeFileThresholdMB = Int($0) }), in: 1...100, step: 1)
                    Text("\(settings.largeFileThresholdMB) MB")
                        .frame(width: 50)
                }

                HStack {
                    Text("Storage Limit")
                    Slider(value: Binding(get: { Double(settings.vaultStorageLimitGB) }, set: { settings.vaultStorageLimitGB = Int($0) }), in: 1...100, step: 1)
                    Text("\(settings.vaultStorageLimitGB) GB")
                        .frame(width: 50)
                }

                Toggle("Auto-trim oldest files when limit reached", isOn: $settings.isAutoTrimEnabled)
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
    @ObservedObject var settings: SettingsManager
    @State private var newLabel = ""
    @State private var newPattern = ""
    
    var body: some View {
        Form {
            Section(header: Text("Encryption & Privacy")) {
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
                .padding(.vertical, 4)

                Picker("Sensitive Auto-Purge", selection: $settings.sensitivePurgeTimeHours) {
                    Text("30 Minutes").tag(0) // Logic for < 1h needed?
                    Text("1 Hour").tag(1)
                    Text("4 Hours").tag(4)
                    Text("24 Hours").tag(24)
                }
                Text("Sensitive content (passwords, cards) is automatically detected and purged.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("Redaction Rules (FTS Index)")) {
                Text("Built-in rules for Credit Cards, SSNs, and Secrets are always active.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                List {
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
                }
                .frame(height: 100)
                
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
        if (try? NSRegularExpression(pattern: newPattern)) != nil {
            settings.customPatterns[newLabel] = newPattern
            newLabel = ""
            newPattern = ""
        }
    }
}

struct AboutSettingsView: View {
    private var buildDate: String {
        if let path = Bundle.main.executablePath,
           let attributes = try? FileManager.default.attributesOfItem(atPath: path),
           let date = attributes[.creationDate] as? Date {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        return "Unknown"
    }

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "clipboard")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
            
            Text("ClipVault")
                .font(.title)
            
            Text("Version 1.1.0")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Build Time: \(buildDate)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("© 2026 ClipVault Team")
                .font(.caption2)
        }
        .padding()
    }
}
