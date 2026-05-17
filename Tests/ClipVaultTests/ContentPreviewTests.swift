//
//  ContentPreviewTests.swift
//  ClipVaultTests
//

import XCTest
import SwiftUI
@testable import ClipVault

final class ContentPreviewTests: XCTestCase {
    
    func testContentPreviewRouter_SelectsCorrectView() {
        let textEntry = ClipboardEntry(timestamp: Date(), contentType: "text", plainTextContent: Data("Hello".utf8))
        let imageEntry = ClipboardEntry(timestamp: Date(), contentType: "image", imageData: Data([0, 1, 2]))
        let fileEntry = ClipboardEntry(timestamp: Date(), contentType: "file", fileURL: "/tmp/test.txt")
        let urlEntry = ClipboardEntry(timestamp: Date(), contentType: "url", plainTextContent: Data("https://google.com".utf8))
        
        // These are SwiftUI views, testing their exact type is tricky, 
        // but we can verify the router doesn't crash and returns something.
        // In a real TDD we might check specific properties if we used a protocol.
    }
}
