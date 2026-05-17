//
//  FilePreview.swift
//  ClipVault
//

import SwiftUI

struct FilePreview: View {
    let filePath: String
    
    var body: some View {
        HStack {
            Image(systemName: "doc")
                .font(.system(size: 24))
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading) {
                Text(URL(fileURLWithPath: filePath).lastPathComponent)
                    .font(.body)
                    .lineLimit(1)
                
                Text(filePath)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
    }
}
