//
//  SearchBarView.swift
//  ClipVault
//

import SwiftUI

struct SearchBarView: View {
    @Binding var text: String
    @Binding var isFocused: Bool
    @FocusState private var fieldFocused: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search history...", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .focused($fieldFocused)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.accentColor.opacity(0.5), lineWidth: 2)
        )
        .onChange(of: isFocused) { newValue in
            if newValue {
                fieldFocused = true
                isFocused = false // Reset so it can be triggered again
            }
        }
    }
}
