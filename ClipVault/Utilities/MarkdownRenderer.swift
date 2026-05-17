//
//  MarkdownRenderer.swift
//  ClipVault
//

import Foundation
import SwiftUI

struct MarkdownRenderer {
    
    /// Parses a string with markdown and returns an AttributedString.
    static func render(_ text: String) -> AttributedString {
        do {
            return try AttributedString(markdown: text, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
        } catch {
            return AttributedString(text)
        }
    }
}
