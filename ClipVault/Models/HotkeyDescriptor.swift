//
//  HotkeyDescriptor.swift
//  ClipVault
//
//  Represents a global keyboard shortcut with modifiers and a key code.
//

import AppKit

/// Describes a global keyboard shortcut as a Codable, Equatable value type.
struct HotkeyDescriptor: Codable, Equatable {
    /// The raw value of NSEvent.ModifierFlags (device-independent mask).
    var modifiers: NSEvent.ModifierFlags
    /// The virtual key code (CGKeyCode / UInt16).
    var keyCode: UInt16

    // MARK: - Codable conformance (NSEvent.ModifierFlags is not Codable by default)

    enum CodingKeys: String, CodingKey {
        case modifiersRawValue
        case keyCode
    }

    init(modifiers: NSEvent.ModifierFlags, keyCode: UInt16) {
        self.modifiers = modifiers
        self.keyCode = keyCode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let raw = try container.decode(UInt.self, forKey: .modifiersRawValue)
        self.modifiers = NSEvent.ModifierFlags(rawValue: raw)
        self.keyCode = try container.decode(UInt16.self, forKey: .keyCode)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(modifiers.rawValue, forKey: .modifiersRawValue)
        try container.encode(keyCode, forKey: .keyCode)
    }

    // MARK: - Equatable

    static func == (lhs: HotkeyDescriptor, rhs: HotkeyDescriptor) -> Bool {
        lhs.keyCode == rhs.keyCode && lhs.modifiers.rawValue == rhs.modifiers.rawValue
    }

    // MARK: - Default

    /// Default: Cmd+Shift+V (keyCode 9 = 'v' on US keyboards)
    static let `default` = HotkeyDescriptor(modifiers: [.command, .shift], keyCode: 9)

    // MARK: - Display

    /// Human-readable string representation of the shortcut (e.g. ⌘⇧V).
    var displayString: String {
        var parts = ""
        let mask = modifiers.intersection(.deviceIndependentFlagsMask)
        if mask.contains(.control) { parts += "⌃" }
        if mask.contains(.option) { parts += "⌥" }
        if mask.contains(.shift) { parts += "⇧" }
        if mask.contains(.command) { parts += "⌘" }
        parts += keyName(for: keyCode)
        return parts
    }

    /// Returns a human-readable key name for common key codes.
    private func keyName(for keyCode: UInt16) -> String {
        let keyNames: [UInt16: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P",
            36: "↩", 37: "L", 38: "J", 39: "'", 40: "K", 41: ";",
            42: "\\", 43: ",", 44: "/", 45: "N", 46: "M", 47: ".",
            48: "⇥", 49: "Space", 50: "`", 51: "⌫", 53: "⎋",
            123: "←", 124: "→", 125: "↓", 126: "↑"
        ]
        return keyNames[keyCode] ?? "(\(keyCode))"
    }
}
