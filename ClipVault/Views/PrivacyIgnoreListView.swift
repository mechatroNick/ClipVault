//
//  PrivacyIgnoreListView.swift
//  ClipVault
//
//  Settings sub-view that lets users configure which apps' clipboard
//  changes are silently rejected by ClipVault.
//

import SwiftUI

/// Settings panel section for the Privacy Ignore List.
struct PrivacyIgnoreListView: View {
    @ObservedObject var settings: SettingsManager
    @State private var newBundleID = ""
    @State private var showingResetConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Privacy Ignore List")
                    .font(.headline)
                Text("ClipVault will silently ignore clipboard changes originating from these apps. Add any app by its macOS Bundle ID (e.g. com.example.app).")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Existing entries
            VStack(spacing: 6) {
                if settings.ignoredBundleIDs.isEmpty {
                    Text("No apps in ignore list.")
                        .foregroundColor(.secondary)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                } else {
                    ForEach(settings.ignoredBundleIDs, id: \.self) { bundleID in
                        HStack {
                            Image(systemName: "app.badge.checkmark")
                                .foregroundColor(.secondary)
                                .font(.caption)
                            Text(bundleID)
                                .font(.system(.body, design: .monospaced))
                            Spacer()
                            Button(action: { remove(bundleID: bundleID) }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Remove \(bundleID) from ignore list")
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }

            // Add new entry
            HStack {
                TextField("com.example.app", text: $newBundleID)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .accessibilityLabel("New bundle ID")

                Button(action: addBundleID) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
                .disabled(newBundleID.trimmingCharacters(in: .whitespaces).isEmpty ||
                          settings.ignoredBundleIDs.contains(newBundleID.trimmingCharacters(in: .whitespaces)))
                .accessibilityLabel("Add to ignore list")
            }

            // Reset to defaults
            HStack {
                Spacer()
                Button("Reset to Defaults") {
                    showingResetConfirmation = true
                }
                .foregroundColor(.secondary)
                .font(.caption)
            }
            .confirmationDialog(
                "Reset ignore list to defaults?",
                isPresented: $showingResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    settings.ignoredBundleIDs = PrivacyIgnoreList.defaultIgnoredBundleIDs
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    // MARK: - Actions

    private func addBundleID() {
        let trimmed = newBundleID.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !settings.ignoredBundleIDs.contains(trimmed) else { return }
        settings.ignoredBundleIDs.append(trimmed)
        newBundleID = ""
    }

    private func remove(bundleID: String) {
        settings.ignoredBundleIDs.removeAll { $0 == bundleID }
    }
}
