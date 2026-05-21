//
//  KeyboardHandler.swift
//  ClipVault
//

import AppKit
import Carbon
import Combine

/// Registers and manages the global keyboard shortcut (hotkey) that opens ClipVault.
/// The hotkey is read from SettingsManager and automatically re-registered when it changes.
@MainActor
final class KeyboardHandler {
    static let shared = KeyboardHandler()

    private var hotKeyRef: EventHotKeyRef?
    /// Retained Carbon event handler — installed once; reused across hotkey re-registrations.
    private var eventHandlerRef: EventHandlerRef?
    var onHotKey: (() -> Void)?

    private var settingsCancellable: AnyCancellable?

    private init() {}

    /// Call once at app startup. Registers the current hotkey and listens for changes.
    func registerHotKey() {
        installCurrentHotKey()

        // Re-register whenever the user changes the hotkey in Settings
        settingsCancellable = SettingsManager.shared.$globalHotkey
            .dropFirst()     // Skip the initial value (already registered above)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.reinstallHotKey()
            }
    }

    func unregisterHotKey() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let ref = eventHandlerRef {
            RemoveEventHandler(ref)
            eventHandlerRef = nil
        }
        settingsCancellable = nil
    }

    // MARK: - Private

    private func reinstallHotKey() {
        // Unregister the old Carbon hotkey binding (NOT the event handler — it is shared)
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        installCurrentHotKey()
    }

    private func installCurrentHotKey() {
        let descriptor = SettingsManager.shared.globalHotkey

        // Convert NSEvent.ModifierFlags → Carbon modifier mask
        let carbonMods = carbonModifiers(from: descriptor.modifiers)

        // Pack "CVLT" into a FourCharCode correctly (shift ASCII values into a UInt32)
        let sig: UInt32 = "CVLT".unicodeScalars.reduce(0) { ($0 << 8) | UInt32($1.value) }

        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = FourCharCode(sig)
        hotKeyID.id = 1

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        // Install the Carbon event handler only once — re-use across re-registrations
        if eventHandlerRef == nil {
            InstallEventHandler(
                GetApplicationEventTarget(),
                { (_, _, _) -> OSStatus in
                    Task { @MainActor in
                        KeyboardHandler.shared.onHotKey?()
                    }
                    return noErr
                },
                1,
                &eventType,
                nil,
                &eventHandlerRef
            )
        }

        RegisterEventHotKey(
            UInt32(descriptor.keyCode),
            carbonMods,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    /// Maps NSEvent.ModifierFlags to Carbon modifier constants.
    private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var carbonMods: UInt32 = 0
        let mask = flags.intersection(.deviceIndependentFlagsMask)
        if mask.contains(.command) { carbonMods |= UInt32(cmdKey) }
        if mask.contains(.shift) { carbonMods |= UInt32(shiftKey) }
        if mask.contains(.option) { carbonMods |= UInt32(optionKey) }
        if mask.contains(.control) { carbonMods |= UInt32(controlKey) }
        return carbonMods
    }
}
