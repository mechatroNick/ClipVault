//
//  PasteService.swift
//  ClipVault
//

import AppKit

/// Handles writing clipboard entries back to the system pasteboard and triggering paste actions.
final class PasteService {
    private let pasteboard: PasteboardProtocol
    
    init(pasteboard: PasteboardProtocol = NSPasteboard.general) {
        self.pasteboard = pasteboard
    }
    
    /// Prepares the pasteboard with the content of the given entry.
    ///
    /// - Parameters:
    ///   - entry: The entry to write to the pasteboard.
    ///   - asPlainText: If true, only plain text content will be written even for rich text entries.
    func preparePasteboard(for entry: ClipboardEntry, asPlainText: Bool = false) async throws {
        pasteboard.clearContents()
        
        if asPlainText {
            if let data = entry.plainTextContent, let string = String(data: data, encoding: .utf8) {
                pasteboard.setString(string, forType: .string)
            }
            return
        }
        
        switch entry.contentType {
        case "image":
            if let data = entry.imageData {
                pasteboard.setData(data, forType: .tiff)
            }
        case "file":
            if let path = entry.fileURL {
                let url = URL(fileURLWithPath: path)
                pasteboard.setString(url.absoluteString, forType: .fileURL)
            }
        case "url":
            if let data = entry.plainTextContent, let string = String(data: data, encoding: .utf8) {
                pasteboard.setString(string, forType: .URL)
                pasteboard.setString(string, forType: .string)
            }
        case "rtf":
            if let data = entry.richTextContent {
                pasteboard.setData(data, forType: .rtf)
            }
            if let data = entry.plainTextContent, let string = String(data: data, encoding: .utf8) {
                pasteboard.setString(string, forType: .string)
            }
        default: // text, code, markdown
            if let data = entry.plainTextContent, let string = String(data: data, encoding: .utf8) {
                pasteboard.setString(string, forType: .string)
            }
        }
    }
    
    /// Simulates a ⌘V paste action using HID events.
    @MainActor
    func simulatePaste() async {
        // Security/UX Hardening: Small delay to let the target application regain focus
        // after the floating panel dismisses.
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        
        let src = CGEventSource(stateID: .combinedSessionState)
        
        let vDown = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: true)
        let vUp = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: false)
        
        vDown?.flags = .maskCommand
        
        vDown?.post(tap: .cghidEventTap)
        vUp?.post(tap: .cghidEventTap)
    }
}
