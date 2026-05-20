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
        guard isValidMarkdown(text) else {
            return AttributedString(text)
        }
        do {
            return try AttributedString(markdown: text, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .full))
        } catch {
            return AttributedString(text)
        }
    }
    
    static func isValidMarkdown(_ text: String) -> Bool {
        // Strict check: count code block markers
        let codeBlockCount = text.components(separatedBy: "```").count - 1
        if codeBlockCount % 2 != 0 { return false }
        
        // Simple check for unclosed inline code
        let inlineCodeCount = text.components(separatedBy: "`").count - 1
        if inlineCodeCount % 2 != 0 { return false }
        
        // Check for unbalanced brackets/parentheses for links
        let openBracket = text.components(separatedBy: "[").count - 1
        let closeBracket = text.components(separatedBy: "]").count - 1
        if openBracket != closeBracket { return false }
        
        let openParen = text.components(separatedBy: "(").count - 1
        let closeParen = text.components(separatedBy: ")").count - 1
        if openParen != closeParen { return false }
        
        return true
    }
}

import PDFKit

struct PDFThumbnailRenderer {
    static func generateThumbnail(from data: Data, width: CGFloat = 200) -> NSImage? {
        guard let document = PDFDocument(data: data),
              let firstPage = document.page(at: 0) else {
            return nil
        }
        
        let pageRect = firstPage.bounds(for: .mediaBox)
        let aspectRatio = pageRect.height / pageRect.width
        let height = width * aspectRatio
        let targetSize = NSSize(width: width, height: height)
        
        return firstPage.thumbnail(of: targetSize, for: .mediaBox)
    }
}

struct RichTextRenderer {
    static func renderRTF(_ data: Data) -> NSAttributedString? {
        return NSAttributedString(rtf: data, documentAttributes: nil)
    }
    
    static func renderHTML(_ data: Data) -> NSAttributedString? {
        guard isValidHTML(data) else { return nil }
        return NSAttributedString(html: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
    }
    
    static func isValidHTML(_ data: Data) -> Bool {
        guard let htmlString = String(data: data, encoding: .utf8) else { return false }
        
        // Use a simple tag-balancing check for strictness
        var tags: [String] = []
        let scanner = Scanner(string: htmlString)
        
        while !scanner.isAtEnd {
            _ = scanner.scanUpToString("<")
            if scanner.isAtEnd { break }
            _ = scanner.scanString("<")
            
            if scanner.scanString("/") != nil {
                // Closing tag
                if let tagName = scanner.scanUpToCharacters(from: CharacterSet(charactersIn: "> ")) {
                    if tags.last == tagName {
                        tags.removeLast()
                    } else {
                        return false // Mismatched or out of order
                    }
                }
                _ = scanner.scanUpToString(">")
                _ = scanner.scanString(">")
            } else {
                // Opening tag
                if let tagName = scanner.scanUpToCharacters(from: CharacterSet(charactersIn: "> ")) {
                    // Ignore self-closing tags
                    let isSelfClosing = ["br", "hr", "img", "input", "link", "meta"].contains(tagName.lowercased())
                    if !isSelfClosing {
                        tags.append(tagName)
                    }
                }
                _ = scanner.scanUpToString(">")
                _ = scanner.scanString(">")
            }
        }
        
        return tags.isEmpty
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
