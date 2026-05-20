//
//  DetailedEntryViewTests.swift
//  ClipVaultTests
//

import XCTest
import SwiftUI
@testable import ClipVault

final class DetailedEntryViewTests: XCTestCase {
    
    func testDetailedEntryView_InitializesWithAllTypes() {
        let repository = ClipboardRepository()
        
        let types: [ClipboardContentType] = [.text, .image, .file, .url, .code, .markdown, .rtf, .html, .unknown]
        
        for type in types {
            let entry = ClipboardEntry(
                timestamp: Date(),
                contentType: type,
                plainTextContent: Data("Test".utf8),
                richTextContent: Data("Test".utf8),
                imageData: Data([0, 1, 2]),
                fileURL: "/tmp/test.txt"
            )
            let view = DetailedEntryView(entry: entry, repository: repository)
            let hosting = NSHostingView(rootView: view)
            hosting.frame = NSRect(x: 0, y: 0, width: 400, height: 300)
            hosting.layout()
        }
    }
    
    func testFileListView_Initializes() {
        let view = FileListView(paths: ["/tmp/test.txt", "/Users/Shared"])
        XCTAssertNotNil(view)
    }
    
    func testFolderContentsView_Initializes() {
        let view = FolderContentsView(url: URL(fileURLWithPath: "/tmp"))
        XCTAssertNotNil(view)
    }
}
