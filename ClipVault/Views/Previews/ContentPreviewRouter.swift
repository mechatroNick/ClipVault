//
//  ContentPreviewRouter.swift
//  ClipVault
//

import SwiftUI

struct ContentPreviewRouter: View {
    let entry: ClipboardEntry
    var decryptedEntry: ClipboardEntry? = nil
    
    var body: some View {
        let currentEntry = decryptedEntry ?? entry
        
        switch currentEntry.contentType {
        case .image, .croppedImage:
            if let imageData = currentEntry.imageData {
                ImagePreview(imageData: imageData, id: currentEntry.id)
            } else {
                Text("Image data missing")
            }
        case .file:
            if let filePath = currentEntry.fileURL {
                FilePreview(filePath: filePath)
            } else {
                Text("File path missing")
            }
        case .pdf:
            if let data = currentEntry.richTextContent {
                PDFThumbnailView(data: data, id: currentEntry.id)
            } else {
                Text("PDF data missing")
            }
        case .url:
            URLPreview(urlString: currentEntry.plainTextSearchContent ?? "No URL")
        case .code:
            TextPreview(text: currentEntry.plainTextSearchContent ?? "", isCode: true)
        case .markdown:
            TextPreview(text: currentEntry.plainTextSearchContent ?? "", isMarkdown: true)
        case .rtf, .html:
            TextPreview(text: currentEntry.plainTextSearchContent ?? "")
        default:
            TextPreview(text: currentEntry.plainTextSearchContent ?? "")
        }
    }
}
