//
//  URLPreview.swift
//  ClipVault
//

import SwiftUI

struct URLPreview: View {
    let urlString: String
    
    var body: some View {
        HStack {
            Image(systemName: "link")
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(urlString)
                    .font(.body)
                    .lineLimit(1)
                    .foregroundColor(.blue)
                
                if let host = URL(string: urlString)?.host {
                    Text(host)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
