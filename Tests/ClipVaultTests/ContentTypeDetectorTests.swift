//
//  ContentTypeDetectorTests.swift
//  ClipVaultTests
//
//  Created by ClipVault.
//

import XCTest
@testable import ClipVault

final class ContentTypeDetectorTests: XCTestCase {
    
    private var detector: ContentTypeDetector!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        detector = ContentTypeDetector()
    }
    
    override func tearDownWithError() throws {
        detector = nil
        try super.tearDownWithError()
    }
    
    func testDetect_FileURL_ReturnsFile() {
        let mock = MockPasteboard()
        mock.types = [.fileURL, .string]
        XCTAssertEqual(detector.detectType(from: mock), "file")
    }
    
    func testDetect_URL_ReturnsUrl() {
        let mock = MockPasteboard()
        mock.types = [.URL, .string]
        XCTAssertEqual(detector.detectType(from: mock), "url")
    }
    
    func testDetect_Image_ReturnsImage() {
        let mock1 = MockPasteboard()
        mock1.types = [.png]
        XCTAssertEqual(detector.detectType(from: mock1), "image")
        
        let mock2 = MockPasteboard()
        mock2.types = [.tiff]
        XCTAssertEqual(detector.detectType(from: mock2), "image")
    }
    
    func testDetect_HTML_ReturnsHtml() {
        let mock = MockPasteboard()
        mock.types = [.html, .string]
        XCTAssertEqual(detector.detectType(from: mock), "html")
    }
    
    func testDetect_RTF_ReturnsRtf() {
        let mock1 = MockPasteboard()
        mock1.types = [.rtf, .string]
        XCTAssertEqual(detector.detectType(from: mock1), "rtf")
        
        let mock2 = MockPasteboard()
        mock2.types = [.rtfd, .string]
        XCTAssertEqual(detector.detectType(from: mock2), "rtf")
    }
    
    func testDetect_String_Plain_ReturnsText() {
        let mock = MockPasteboard()
        mock.simulateCopy(string: "Just a normal string", type: .string)
        XCTAssertEqual(detector.detectType(from: mock), "text")
    }
    
    func testDetect_String_Markdown_ReturnsMarkdown() {
        let mocks = [
            "Here is some ```swift code``` inside",
            "## Header 2",
            "Some **bold** text",
            "A [link](https://example.com)"
        ]
        
        for string in mocks {
            let mock = MockPasteboard()
            mock.simulateCopy(string: string, type: .string)
            XCTAssertEqual(detector.detectType(from: mock), "markdown", "Failed on string: \(string)")
        }
    }
    
    func testDetect_String_Code_ReturnsCode() {
        let codeString = """
        import Foundation
        
        class TestClass {
            func test() {
                let x = 1;
            }
        }
        """
        let mock = MockPasteboard()
        mock.simulateCopy(string: codeString, type: .string)
        XCTAssertEqual(detector.detectType(from: mock), "code")
    }
    
    func testDetect_Unknown_ReturnsUnknown() {
        let mock = MockPasteboard()
        mock.types = []
        XCTAssertEqual(detector.detectType(from: mock), "unknown")
    }
}
