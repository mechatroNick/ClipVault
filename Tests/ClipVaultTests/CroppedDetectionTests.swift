//
//  CroppedDetectionTests.swift
//  ClipVaultTests
//

import XCTest
import AppKit
@testable import ClipVault

final class CroppedDetectionTests: XCTestCase {
    
    private var detector: ContentTypeDetector!
    private var mockPasteboard: MockPasteboard!
    
    override func setUp() {
        super.setUp()
        detector = ContentTypeDetector()
        mockPasteboard = MockPasteboard()
    }
    
    func testDetectType_ImageFile_ReturnsFile() {
        mockPasteboard.mockTypes = [.fileURL, .tiff, .png]
        mockPasteboard.mockString = "file:///Users/nd/test.png"
        
        let type = detector.detectType(from: mockPasteboard)
        XCTAssertEqual(type, .file)
    }
    
    func testDetectType_CroppedImage_ReturnsCroppedImage() {
        mockPasteboard.mockTypes = [.tiff, .png]
        mockPasteboard.mockData = Data([0x01, 0x02])
        
        let type = detector.detectType(from: mockPasteboard)
        XCTAssertEqual(type, .croppedImage)
    }
}
