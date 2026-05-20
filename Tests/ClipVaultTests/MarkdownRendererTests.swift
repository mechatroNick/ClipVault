//
//  MarkdownRendererTests.swift
//  ClipVaultTests
//

import XCTest
@testable import ClipVault

final class MarkdownRendererTests: XCTestCase {
    
    func testIsValidMarkdown_ValidContent_ReturnsTrue() {
        let valid = "This is **bold** and `code`."
        XCTAssertTrue(MarkdownRenderer.isValidMarkdown(valid))
        
        let validBlock = "```swift\nlet x = 1\n```"
        XCTAssertTrue(MarkdownRenderer.isValidMarkdown(validBlock))
    }
    
    func testIsValidMarkdown_InvalidContent_ReturnsFalse() {
        let invalidBlock = "```swift\nlet x = 1" // Unclosed block
        XCTAssertFalse(MarkdownRenderer.isValidMarkdown(invalidBlock))
        
        let invalidInline = "This is `unclosed code"
        XCTAssertFalse(MarkdownRenderer.isValidMarkdown(invalidInline))
        
        let invalidBrackets = "This is [a link](https://example.com" // Unclosed parens/brackets
        XCTAssertFalse(MarkdownRenderer.isValidMarkdown(invalidBrackets))
    }
    
    func testIsValidHTML_ValidContent_ReturnsTrue() {
        let valid = "<html><body><h1>Hello</h1></body></html>".data(using: .utf8)!
        XCTAssertTrue(RichTextRenderer.isValidHTML(valid))
        
        let validSelfClosing = "<div><br><p>Test</p></div>".data(using: .utf8)!
        XCTAssertTrue(RichTextRenderer.isValidHTML(validSelfClosing))
    }
    
    func testIsValidHTML_InvalidContent_ReturnsFalse() {
        let invalid = "<html><body><h1>Hello</h1></body>".data(using: .utf8)! // Unclosed html
        XCTAssertFalse(RichTextRenderer.isValidHTML(invalid))
        
        let mismatched = "<div><span></div></span>".data(using: .utf8)!
        XCTAssertFalse(RichTextRenderer.isValidHTML(mismatched))
    }
}
