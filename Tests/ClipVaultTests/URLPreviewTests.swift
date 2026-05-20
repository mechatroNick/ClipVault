//
//  URLPreviewTests.swift
//  ClipVaultTests
//

import XCTest
import SwiftUI
@testable import ClipVault

final class URLPreviewTests: XCTestCase {
    func testURLPreview_InitializesWithValidURL() {
        let view = URLPreview(urlString: "https://google.com")
        let hosting = NSHostingView(rootView: view)
        hosting.frame = NSRect(x: 0, y: 0, width: 200, height: 100)
        hosting.layout()
    }
    
    func testURLPreview_InitializesWithInvalidURL() {
        let view = URLPreview(urlString: "not a url")
        let hosting = NSHostingView(rootView: view)
        hosting.frame = NSRect(x: 0, y: 0, width: 200, height: 100)
        hosting.layout()
    }
}
