//
//  EntryRowView.swift
//  ClipVault
//

import SwiftUI

struct EntryRowView: View {
    let entry: ClipboardEntry
    let isSelected: Bool
    let repository: ClipboardRepository
    var onTogglePin: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    var onCopy: (() -> Void)? = nil
    
    @State private var isHovered = false
    @State private var fileExists = true
    @State private var decryptedEntry: ClipboardEntry? = nil
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Content Preview
            VStack(alignment: .leading, spacing: 4) {
                ContentPreviewRouter(entry: entry)
                    .foregroundColor(isSelected ? .white : .primary)
                
                if let windowTitle = entry.windowTitle {
                    Text(windowTitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .primary.opacity(0.8))
                        .lineLimit(1)
                }

                HStack(spacing: 8) {
                    Text(entry.contentType.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(3)
                    
                    Text(relativeTimestamp(for: entry.timestamp))
                        .font(.system(size: 10))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    
                    if let app = entry.sourceApplication {
                        Text(app)
                            .font(.system(size: 10))
                            .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                            .lineLimit(1)
                    }
                    
                    if entry.isRemote {
                        HStack(spacing: 2) {
                            Image(systemName: "iphone")
                            Text("iPhone")
                        }
                        .font(.system(size: 10))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    } else {
                        HStack(spacing: 2) {
                            Image(systemName: "desktopcomputer")
                            Text("This Mac")
                        }
                        .font(.system(size: 10))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    }

                    if entry.contentType == "file" && !fileExists {
                        HStack(spacing: 2) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text("Missing")
                        }
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.red)
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                if isSelected || isHovered || entry.isPinned {
                    Button(action: { onCopy?() }) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(isSelected ? .white : .secondary)
                    .accessibilityLabel("Copy")

                    Button(action: { onTogglePin?() }) {
                        Image(systemName: entry.isPinned ? "pin.fill" : "pin")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(isSelected ? .white : .secondary)
                    .accessibilityLabel(entry.isPinned ? "Unpin" : "Pin")
                    
                    Button(action: { onDelete?() }) {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(isSelected ? .white : .secondary)
                    .accessibilityLabel("Delete")
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
        .onHover { hovering in
            isHovered = hovering
            if hovering && decryptedEntry == nil {
                Task {
                    do {
                        decryptedEntry = try repository.decryptContent(for: entry)
                    } catch {
                        print("Failed to decrypt for hover: \(error)")
                    }
                }
            }
        }
        .popover(isPresented: $isHovered, arrowEdge: .trailing) {
            VStack {
                ContentPreviewRouter(entry: entry, decryptedEntry: decryptedEntry)
                    .padding()
                    .frame(maxWidth: 400, maxHeight: 400)
            }
        }
        .onAppear {
            validateFile()
        }
    }

    private func relativeTimestamp(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func validateFile() {
        guard entry.contentType == "file", let path = entry.fileURL else { return }
        let paths = path.components(separatedBy: "\n")
        for p in paths {
            if !FileManager.default.fileExists(atPath: p) {
                fileExists = false
                return
            }
        }
        fileExists = true
    }
}
