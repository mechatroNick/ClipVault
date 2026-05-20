//
//  ContentTypeDetector.swift
//  ClipVault
//
//  Created by ClipVault.
//

import AppKit

/// Inspects the pasteboard to determine the best semantic content type string.
struct ContentTypeDetector {
    
    /// Returns the semantic content type detected from the pasteboard.
    func detectType(from pasteboard: PasteboardProtocol) -> ClipboardContentType {
        let types = pasteboard.types ?? []
        
        if types.contains(.fileURL) {
            if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
               urls.count == 1,
               urls.first?.pathExtension.lowercased() == "pdf" {
                return .pdf
            }
            return .file
        }
        
        if types.contains(.URL) {
            return .url
        }
        
        if types.contains(.pdf) {
            return .pdf
        }
        
        if types.contains(.png) || types.contains(.tiff) {
            return .croppedImage
        }
        
        if types.contains(.html) {
            return .html
        }
        
        if types.contains(.rtf) || types.contains(.rtfd) {
            return .rtf
        }
        
        if types.contains(.string) {
            if let text = pasteboard.string(forType: .string) {
                if isMarkdown(text) {
                    return .markdown
                }
                if isCode(text) {
                    return .code
                }
                return .text
            }
        }
        
        return .unknown
    }
    
    private func isMarkdown(_ text: String) -> Bool {
        if text.contains("```") { return true }
        if text.contains("**") { return true }
        if text.range(of: "^#{1,6}\\s", options: .regularExpression) != nil { return true }
        if text.range(of: "\\[[^\\]]+\\]\\([^\\)]+\\)", options: .regularExpression) != nil { return true }
        return false
    }
    
    private func isCode(_ text: String) -> Bool {
        // A simple heuristic checking for a mix of keywords and structural symbols.
        let keywords = ["func ", "import ", "struct ", "class ", "let ", "var ", "public ", "private ", "def ", "function ", "const "]
        let symbols = ["{", "}", "()", "=>", ";", "==="]
        
        var hitCount = 0
        for kw in keywords where text.contains(kw) { hitCount += 1 }
        for sym in symbols where text.contains(sym) { hitCount += 1 }
        
        return hitCount >= 3
    }
}
