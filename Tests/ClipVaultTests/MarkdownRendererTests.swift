//
//  MarkdownRendererTests.swift
//  ClipVaultTests
//

import XCTest
@testable import ClipVault

final class MarkdownRendererTests: XCTestCase {
    
    func testRender_BoldText() {
        let input = "Hello **World**"
        let result = MarkdownRenderer.render(input)
        
        // AttributedString testing is best done by checking for specific intents
        // but since we used the built-in initializer, we trust Foundation.
        // We at least verify it doesn't return the same string.
        XCTAssertNotEqual(String(result.characters), input)
        XCTAssertTrue(String(result.characters).contains("World"))
        XCTAssertFalse(String(result.characters).contains("**"))
    }
    
    func testRender_PlainText_ReturnsSameCharacters() {
        let input = "Hello World"
        let result = MarkdownRenderer.render(input)
        XCTAssertEqual(String(result.characters), input)
    }
}
