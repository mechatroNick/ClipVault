//
//  EntryRowView.swift
//  ClipVault
//

import SwiftUI

struct EntryRowView: View {
    let entry: ClipboardEntry
    let isSelected: Bool
    var onTogglePin: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Content Preview
            VStack(alignment: .leading, spacing: 4) {
                ContentPreviewRouter(entry: entry)
                    .foregroundColor(isSelected ? .white : .primary)
                
                HStack(spacing: 8) {
                    Text(entry.contentType.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(3)
                    
                    Text(entry.timestamp, style: .time)
                        .font(.system(size: 10))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    
                    if let app = entry.sourceApplication {
                        Text(app)
                            .font(.system(size: 10))
                            .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                if isSelected || entry.isPinned {
                    Button(action: { onTogglePin?() }) {
                        Image(systemName: entry.isPinned ? "pin.fill" : "pin")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(isSelected ? .white : .secondary)
                    
                    Button(action: { onDelete?() }) {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(isSelected ? .white : .secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isSelected ? Color.accentColor : Color.clear)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.accentColor, lineWidth: isSelected ? 2 : 0)
        )
    }
}
