//
//  DetailedEntryView.swift
//  ClipVault
//

import SwiftUI
import GRDB

struct DetailedEntryView: View {
    let entry: ClipboardEntry
    @State private var decryptedEntry: ClipboardEntry?
    let repository: ClipboardRepository
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(entry.sourceApplication ?? "Unknown Source")
                    .font(.headline)
                Spacer()
                Text(entry.timestamp, style: .date)
                Text(entry.timestamp, style: .time)
            }
            .foregroundColor(.secondary)
            
            Divider()
            
            if let decrypted = decryptedEntry {
                if entry.contentType == .pdf {
                    contentView(for: decrypted)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                } else {
                    ScrollView {
                        contentView(for: decrypted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            } else {
                ProgressView("Decrypting...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
        .frame(minWidth: 400, idealWidth: 600, minHeight: 300, idealHeight: 400)
        .onAppear {
            Task {
                decryptedEntry = try? repository.decryptContent(for: entry)
            }
        }
    }
    
    @ViewBuilder
    private func contentView(for decEntry: ClipboardEntry) -> some View {
        switch decEntry.contentType {
        case .image, .croppedImage:
            if let imageData = decEntry.imageData, let nsImage = NSImage(data: imageData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
            } else {
                Text("Failed to load image.")
            }
        case .file:
            if let path = decEntry.fileURL {
                FileListView(paths: path.components(separatedBy: "\n"))
            } else {
                Text("No file path available.")
            }
        case .pdf:
            if let data = decEntry.richTextContent {
                PDFKitView(data: data)
            } else {
                Text("PDF data missing")
            }
        case .url:
            Text(decEntry.plainTextSearchContent ?? "No URL")
                .textSelection(.enabled)
        case .code:
            Text(decEntry.plainTextSearchContent ?? "")
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
        case .markdown:
            Text(MarkdownRenderer.render(decEntry.plainTextSearchContent ?? ""))
                .textSelection(.enabled)
        case .rtf:
            if let data = decEntry.richTextContent, let attrStr = RichTextRenderer.renderRTF(data), let swAttr = try? AttributedString(attrStr, including: \.appKit) {
                Text(swAttr).textSelection(.enabled)
            } else {
                Text(decEntry.plainTextSearchContent ?? "").textSelection(.enabled)
            }
        case .html:
            if let data = decEntry.richTextContent, let attrStr = RichTextRenderer.renderHTML(data), let swAttr = try? AttributedString(attrStr, including: \.appKit) {
                Text(swAttr).textSelection(.enabled)
            } else {
                Text(decEntry.plainTextSearchContent ?? "").textSelection(.enabled)
            }
        default:
            Text(decEntry.plainTextSearchContent ?? "")
                .textSelection(.enabled)
        }
    }
}

struct FileListView: View {
    let paths: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(paths, id: \.self) { path in
                let url = URL(fileURLWithPath: path)
                HStack {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: path))
                        .resizable()
                        .frame(width: 32, height: 32)
                    VStack(alignment: .leading) {
                        Text(url.lastPathComponent)
                            .font(.headline)
                        if url.hasDirectoryPath || (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true {
                            FolderContentsView(url: url)
                        } else {
                            Text(path)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                Divider()
            }
        }
    }
}

struct FolderContentsView: View {
    let url: URL
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(url.path)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let contents = try? FileManager.default.contentsOfDirectory(atPath: url.path) {
                let displayContents = contents.prefix(10)
                ForEach(displayContents, id: \.self) { item in
                    Text(" • \(item)")
                        .font(.caption)
                }
                if contents.count > 10 {
                    Text("   ... and \(contents.count - 10) more items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
