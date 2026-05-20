//
//  PDFPreview.swift
//  ClipVault
//

import SwiftUI
import PDFKit

struct PDFThumbnailView: View {
    let data: Data
    var id: Int64? = nil
    
    @State private var thumbnail: NSImage?
    
    var body: some View {
        Group {
            if let cached = getCachedThumbnail() {
                renderImage(cached)
            } else if let thumb = thumbnail {
                renderImage(thumb)
            } else {
                HStack {
                    Image(systemName: "doc.text.fill")
                    Text("PDF")
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
                .frame(width: 100, height: 100)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(4)
                .onAppear {
                    generateThumbnail()
                }
            }
        }
    }
    
    private func renderImage(_ image: NSImage) -> some View {
        Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 200, maxHeight: 100)
            .cornerRadius(4)
    }
    
    private func getCachedThumbnail() -> NSImage? {
        guard let id = id else { return nil }
        return ThumbnailCache.shared.get(for: id)
    }
    
    private func generateThumbnail() {
        // Run on background thread
        Task.detached(priority: .userInitiated) {
            if let thumb = PDFThumbnailRenderer.generateThumbnail(from: data) {
                await MainActor.run {
                    self.thumbnail = thumb
                    if let id = id {
                        ThumbnailCache.shared.set(thumb, for: id)
                    }
                }
            }
        }
    }
}

/// A wrapper for PDFView to be used in SwiftUI.
struct PDFKitView: NSViewRepresentable {
    let data: Data
    
    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(data: data)
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        
        // Advanced features
        pdfView.interpolationQuality = .high
        pdfView.enableDataDetectors = true
        
        return pdfView
    }
    
    func updateNSView(_ nsView: PDFView, context: Context) {
        // Update document if data changes
        if nsView.document?.dataRepresentation() != data {
            nsView.document = PDFDocument(data: data)
        }
    }
}
