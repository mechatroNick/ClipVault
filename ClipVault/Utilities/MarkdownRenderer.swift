//
//  MarkdownRenderer.swift
//  ClipVault
//

import Foundation
import SwiftUI
import AppKit

struct MarkdownRenderer {
    
    /// Parses a string with markdown and returns an AttributedString.
    static func render(_ text: String) -> AttributedString {
        do {
            return try AttributedString(markdown: text, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .full))
        } catch {
            return AttributedString(text)
        }
    }
}

struct RichTextRenderer {
    static func renderRTF(_ data: Data) -> NSAttributedString? {
        return NSAttributedString(rtf: data, documentAttributes: nil)
    }
    
    static func renderHTML(_ data: Data) -> NSAttributedString? {
        return NSAttributedString(html: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
    }
}

struct RichTextPreview: View {
    let attributedString: NSAttributedString
    
    var body: some View {
        if let attrStr = try? AttributedString(attributedString, including: \.appKit) {
            Text(attrStr)
                .lineLimit(3)
                .truncationMode(.tail)
        } else {
            Text(attributedString.string)
                .lineLimit(3)
                .truncationMode(.tail)
        }
    }
}
