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

struct RichTextPreview: NSViewRepresentable {
    let attributedString: NSAttributedString
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        
        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.textStorage?.setAttributedString(attributedString)
        
        scrollView.documentView = textView
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let textView = nsView.documentView as? NSTextView {
            textView.textStorage?.setAttributedString(attributedString)
        }
    }
}
