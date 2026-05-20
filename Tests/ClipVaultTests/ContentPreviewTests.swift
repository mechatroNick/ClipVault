//
//  ContentPreviewTests.swift
//  ClipVaultTests
//

import XCTest
import SwiftUI
@testable import ClipVault

final class ContentPreviewTests: XCTestCase {
    
    func testContentPreviewRouter_SelectsCorrectView() {
        let textEntry = ClipboardEntry(timestamp: Date(), contentType: .text, plainTextContent: Data("Hello".utf8))
        let imageEntry = ClipboardEntry(timestamp: Date(), contentType: .image, imageData: Data([0, 1, 2]))
        let fileEntry = ClipboardEntry(timestamp: Date(), contentType: .file, fileURL: "/tmp/test.txt")
        let urlEntry = ClipboardEntry(timestamp: Date(), contentType: .url, plainTextContent: Data("https://google.com".utf8))
        
        let entries = [textEntry, imageEntry, fileEntry, urlEntry]
        
        for entry in entries {
            let view = ContentPreviewRouter(entry: entry)
            let hosting = NSHostingView(rootView: view)
            hosting.frame = NSRect(x: 0, y: 0, width: 100, height: 100)
            hosting.layout()
        }
    }
}
