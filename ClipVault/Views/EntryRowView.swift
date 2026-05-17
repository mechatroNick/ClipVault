//
//  EntryRowView.swift
//  ClipVault
//

import SwiftUI

struct EntryRowView: View {
    let entry: ClipboardEntry
    let isSelected: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Content Preview
            VStack(alignment: .leading, spacing: 4) {
                if entry.contentType == "image", let imageData = entry.imageData, let image = NSImage(data: imageData) {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 200, maxHeight: 100)
                        .cornerRadius(4)
                } else {
                    Text(entry.plainTextSearchContent ?? "No content")
                        .font(.system(size: 13))
                        .lineLimit(3)
                        .foregroundColor(isSelected ? .white : .primary)
                }
                
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
            
            if entry.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? .white : .secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isSelected ? Color.accentColor : Color.clear)
        .cornerRadius(6)
    }
}
