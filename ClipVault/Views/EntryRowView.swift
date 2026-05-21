//
//  EntryRowView.swift
//  ClipVault
//

import SwiftUI

struct EntryRowView: View {
    let entry: ClipboardEntry
    let isSelected: Bool
    let isActive: Bool
    let repository: ClipboardRepository
    var onTogglePin: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    var onCopy: (() -> Void)? = nil
    var onSelect: (() -> Void)? = nil
    
    @State private var isHovered = false
    @State private var fileExists = true
    @State private var decryptedEntry: ClipboardEntry? = nil
    @State private var showCopiedCheckmark = false
    @State private var showDetailedView = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon / Type indicator
            Image(systemName: iconName)
                .font(.system(size: 14))
                .foregroundColor(isSelected ? .white : .accentColor)
                .frame(width: 24, height: 24)
                .background(isSelected ? Color.white.opacity(0.2) : Color.accentColor.opacity(0.1))
                .cornerRadius(6)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if let app = entry.sourceApplication {
                        Text(app.components(separatedBy: ".").last?.capitalized ?? app)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(isSelected ? .white.opacity(0.9) : .primary.opacity(0.7))
                    }
                    
                    if let window = entry.windowTitle, !window.isEmpty {
                        Text("•")
                            .foregroundColor(isSelected ? .white.opacity(0.5) : .secondary.opacity(0.5))
                        Text(window)
                            .font(.system(size: 11))
                            .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary)
                            .lineLimit(1)
                    }
                    
                    if entry.isRemote {
                        Image(systemName: "icloud")
                            .font(.system(size: 10))
                            .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary)
                    }
                    
                    if isActive {
                        Text("Active")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.green.opacity(isSelected ? 0.3 : 0.2))
                            .foregroundColor(isSelected ? .white : .green)
                            .cornerRadius(4)
                    }
                    
                    if entry.contentType == .croppedImage {
                        Text("Cropped")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.orange.opacity(isSelected ? 0.3 : 0.2))
                            .foregroundColor(isSelected ? .white : .orange)
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    Text(entry.timestamp, style: .time)
                        .font(.system(size: 10))
                        .foregroundColor(isSelected ? .white.opacity(0.6) : .secondary.opacity(0.6))
                }
                
                ContentPreviewRouter(entry: entry, decryptedEntry: decryptedEntry)
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 2)
                
                if entry.contentType == .file && !fileExists {
                    Label("File moved or deleted", systemImage: "exclamationmark.triangle")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
            
            HStack(spacing: 8) {
                if isSelected || isHovered || entry.isPinned {
                    Button(action: { 
                        onCopy?()
                        triggerHapticFeedback()
                        withAnimation(.spring()) {
                            showCopiedCheckmark = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation {
                                showCopiedCheckmark = false
                            }
                        }
                    }) {
                        Image(systemName: showCopiedCheckmark ? "checkmark.circle.fill" : "doc.on.doc")
                            .font(.system(size: 10))
                            .foregroundColor(showCopiedCheckmark ? .green : (isSelected ? .white : .secondary))
                            .scaleEffect(isHovered ? 1.1 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Copy")

                    Button(action: { 
                        onTogglePin?()
                        triggerHapticFeedback()
                    }) {
                        Image(systemName: entry.isPinned ? "pin.fill" : "pin")
                            .font(.system(size: 10))
                            .scaleEffect(isHovered ? 1.1 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(isSelected ? .white : .secondary)
                    .accessibilityLabel(entry.isPinned ? "Unpin" : "Pin")
                    
                    Button(action: { 
                        onDelete?()
                        triggerHapticFeedback()
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                            .scaleEffect(isHovered ? 1.1 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(isSelected ? .white : .secondary)
                    .accessibilityLabel("Delete")
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isSelected ? Color.accentColor : Color.primary.opacity(isHovered ? 0.05 : 0))
        .cornerRadius(8)
        .shadow(color: .black.opacity(isSelected ? 0.2 : 0), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.accentColor.opacity(isSelected ? 1 : 0), lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
            if hovering && decryptedEntry == nil {
                Task {
                    decryptedEntry = try? repository.decryptContent(for: entry)
                }
            }
        }
        .onAppear {
            validateFile()
            if entry.contentType == .image || entry.contentType == .croppedImage || entry.contentType == .pdf {
                Task {
                    decryptedEntry = try? repository.decryptContent(for: entry)
                }
            }
        }
        .onTapGesture(count: 2) {
            onSelect?()
            showDetailedView = true
        }
        .popover(isPresented: $showDetailedView, arrowEdge: .trailing) {
            DetailedEntryView(entry: entry, repository: repository)
        }
    }
    
    private var iconName: String {
        switch entry.contentType {
        case .text: return "text.alignleft"
        case .image, .croppedImage: return "photo"
        case .file: return "doc"
        case .pdf: return "doc.text.fill"
        case .url: return "link"
        case .html: return "chevron.left.forwardslash.chevron.right"
        case .rtf: return "doc.richtext"
        case .markdown: return "text.badge.checkmark"
        case .code: return "chevron.left.forwardslash.chevron.right"
        default: return "doc.on.clipboard"
        }
    }
    
    private func validateFile() {
        guard entry.contentType == .file, let path = entry.fileURL else { return }
        let paths = path.components(separatedBy: "\n")
        for p in paths {
            if !FileManager.default.fileExists(atPath: p) {
                fileExists = false
                return
            }
        }
        fileExists = true
    }

    private func triggerHapticFeedback() {
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
    }
}
