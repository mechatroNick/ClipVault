//
//  TextPreview.swift
//  ClipVault
//

import SwiftUI

struct TextPreview: View {
    let text: String
    let isCode: Bool
    
    var body: some View {
        Text(text)
            .font(isCode ? .system(.body, design: .monospaced) : .body)
            .lineLimit(3)
            .truncationMode(.tail)
    }
}
