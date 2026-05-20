//
//  ImagePreview.swift
//  ClipVault
//

import SwiftUI

struct ImagePreview: View {
    let imageData: Data
    var id: Int64? = nil
    
    var body: some View {
        if let cached = getCachedImage() {
            renderImage(cached)
        } else if let nsImage = NSImage(data: imageData) {
            renderImage(nsImage)
                .onAppear {
                    if let id = id {
                        ThumbnailCache.shared.set(nsImage, for: id)
                    }
                }
        } else {
            Image(systemName: "photo")
                .foregroundColor(.secondary)
        }
    }

    private func renderImage(_ image: NSImage) -> some View {
        Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 200, maxHeight: 100)
            .cornerRadius(4)
    }

    private func getCachedImage() -> NSImage? {
        guard let id = id else { return nil }
        return ThumbnailCache.shared.get(for: id)
    }
}
