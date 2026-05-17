//
//  ImagePreview.swift
//  ClipVault
//

import SwiftUI

struct ImagePreview: View {
    let imageData: Data
    
    var body: some View {
        if let nsImage = NSImage(data: imageData) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 200, maxHeight: 100)
                .cornerRadius(4)
        } else {
            Image(systemName: "photo")
                .foregroundColor(.secondary)
        }
    }
}
