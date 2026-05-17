//
//  ContentPreviewRouter.swift
//  ClipVault
//

import SwiftUI

struct ContentPreviewRouter: View {
    let entry: ClipboardEntry
    
    var body: some View {
        switch entry.contentType {
        case "image":
            if let imageData = entry.imageData {
                ImagePreview(imageData: imageData)
            } else {
                Text("Image data missing")
            }
        case "file":
            if let filePath = entry.fileURL {
                FilePreview(filePath: filePath)
            } else {
                Text("File path missing")
            }
        case "url":
            URLPreview(urlString: entry.plainTextSearchContent ?? "No URL")
        case "code", "markdown":
            TextPreview(text: entry.plainTextSearchContent ?? "", isCode: true)
        default:
            TextPreview(text: entry.plainTextSearchContent ?? "", isCode: false)
        }
    }
}
