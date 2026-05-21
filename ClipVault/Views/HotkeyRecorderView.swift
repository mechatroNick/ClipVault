//
//  HotkeyRecorderView.swift
//  ClipVault
//
//  A UI control for recording a custom global keyboard shortcut.
//  Clicking the control enters "recording" mode; the next key combination
//  (with at least one modifier) is captured and stored.
//

import SwiftUI
import AppKit

/// A control that lets the user set a custom global keyboard shortcut.
struct HotkeyRecorderView: View {
    @Binding var hotkey: HotkeyDescriptor
    @State private var isRecording = false
    @State private var localMonitor: Any?

    var body: some View {
        HStack(spacing: 8) {
            Button(action: toggleRecording) {
                Text(isRecording ? "Recording… (press shortcut)" : hotkey.displayString)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(isRecording ? .orange : .primary)
                    .frame(minWidth: 120, alignment: .center)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isRecording ? Color.orange : Color.secondary.opacity(0.5), lineWidth: 1)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(isRecording ? Color.orange.opacity(0.08) : Color.secondary.opacity(0.05))
                            )
                    )
            }
            .buttonStyle(.plain)

            if hotkey != .default {
                Button(action: resetToDefault) {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .help("Reset to default (⌘⇧V)")
            }
        }
        .onDisappear { stopRecording() }
    }

    // MARK: - Recording Logic

    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        isRecording = true
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [self] event in
            let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            // Require at least one modifier key (other than just function key)
            let requiresMod: NSEvent.ModifierFlags = [.command, .control, .option, .shift]
            guard mods.intersection(requiresMod) != [] else { return event }

            // Escape cancels recording without changing hotkey
            if event.keyCode == 53 {
                stopRecording()
                return nil
            }

            self.hotkey = HotkeyDescriptor(modifiers: mods, keyCode: event.keyCode)
            self.stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        isRecording = false
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }

    private func resetToDefault() {
        hotkey = .default
    }
}
