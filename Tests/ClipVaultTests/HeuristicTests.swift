//
//  HeuristicTests.swift
//  ClipVaultTests
//

import XCTest
@testable import ClipVault

final class HeuristicTests: XCTestCase {
    private var detector: ContentTypeDetector!
    
    override func setUp() {
        super.setUp()
        detector = ContentTypeDetector()
    }
    
    func testMarkdownHeuristics() {
        let md1 = "### Header"
        let md2 = "This is **bold**"
        let md3 = "Check out [this link](https://google.com)"
        let md4 = "Code block:\n\`\`\`swift\nlet x = 1\n\`\`\`"
        
        let mock = MockPasteboard()
        
        mock.simulateCopy(string: md1, type: .string)
        XCTAssertEqual(detector.detectType(from: mock), .markdown)
        
        mock.simulateCopy(string: md2, type: .string)
        XCTAssertEqual(detector.detectType(from: mock), .markdown)
        
        mock.simulateCopy(string: md3, type: .string)
        XCTAssertEqual(detector.detectType(from: mock), .markdown)
        
        mock.simulateCopy(string: md4, type: .string)
        XCTAssertEqual(detector.detectType(from: mock), .markdown)
    }
    
    func testCodeHeuristics() {
        let code1 = "func myFunction() { print(\"test\"); }"
        let code2 = "import SwiftUI\nstruct MyView: View { var body: some View { EmptyView() } }"
        let code3 = "const x = () => { return 1; };"
        
        let mock = MockPasteboard()
        
        mock.simulateCopy(string: code1, type: .string)
        XCTAssertEqual(detector.detectType(from: mock), .code)
        
        mock.simulateCopy(string: code2, type: .string)
        XCTAssertEqual(detector.detectType(from: mock), .code)
        
        mock.simulateCopy(string: code3, type: .string)
        XCTAssertEqual(detector.detectType(from: mock), .code)
    }
}
