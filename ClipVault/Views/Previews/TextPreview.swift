//
//  TextPreview.swift
//  ClipVault
//

import SwiftUI

struct TextPreview: View {
    let text: String
    let isCode: Bool
    let isMarkdown: Bool
    
    init(text: String, isCode: Bool = false, isMarkdown: Bool = false) {
        self.text = text
        self.isCode = isCode
        self.isMarkdown = isMarkdown
    }
    
    var body: some View {
        Group {
            if isMarkdown {
                Text(MarkdownRenderer.render(text))
            } else {
                Text(text)
            }
        }
        .font(isCode ? .system(.body, design: .monospaced) : .body)
        .lineLimit(3)
        .truncationMode(.tail)
    }
}
