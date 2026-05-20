//
//  ImagePreviewTests.swift
//  ClipVaultTests
//

import XCTest
import SwiftUI
@testable import ClipVault

final class ImagePreviewTests: XCTestCase {
    func testImagePreview_InitializesWithData() {
        let nsImage = NSImage(size: NSSize(width: 10, height: 10))
        nsImage.lockFocus()
        NSColor.red.set()
        NSRect(x: 0, y: 0, width: 10, height: 10).fill()
        nsImage.unlockFocus()
        
        let imageData = nsImage.tiffRepresentation!
        let view = ImagePreview(imageData: imageData)
        let hosting = NSHostingView(rootView: view)
        hosting.frame = NSRect(x: 0, y: 0, width: 100, height: 100)
        hosting.layout()
        XCTAssertNotNil(hosting)
    }
}
