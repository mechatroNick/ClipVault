//
//  PasteServiceTests.swift
//  ClipVaultTests
//

import XCTest
@testable import ClipVault

final class PasteServiceTests: XCTestCase {
    
    private var mockPasteboard: MockPasteboard!
    private var monitor: PasteboardMonitor!
    private var pasteService: PasteService!
    
    override func setUp() {
        super.setUp()
        mockPasteboard = MockPasteboard()
        monitor = PasteboardMonitor(pasteboard: mockPasteboard)
        pasteService = PasteService(pasteboard: mockPasteboard, monitor: monitor)
    }
    
    func testPasteText_WritesToPasteboard() async throws {
        let entry = ClipboardEntry(timestamp: Date(), contentType: .text, plainTextContent: Data("Hello Paste".utf8))
        try await pasteService.preparePasteboard(for: entry)
        XCTAssertEqual(mockPasteboard.string(forType: .string), "Hello Paste")
    }

    func testPasteText_AsPlainText_WritesOnlyString() async throws {
        let entry = ClipboardEntry(timestamp: Date(), contentType: .rtf, plainTextContent: Data("Plain".utf8), richTextContent: Data("Rich".utf8))
        try await pasteService.preparePasteboard(for: entry, asPlainText: true)
        XCTAssertEqual(mockPasteboard.string(forType: .string), "Plain")
        XCTAssertNil(mockPasteboard.data(forType: .rtf))
    }
    
    func testPasteImage_WritesToPasteboard() async throws {
        let tiffData = Data([0x01, 0x02])
        let entry = ClipboardEntry(timestamp: Date(), contentType: .image, imageData: tiffData)
        try await pasteService.preparePasteboard(for: entry)
        XCTAssertEqual(mockPasteboard.data(forType: .tiff), tiffData)
    }
    
    func testPasteFile_WritesToPasteboard() async throws {
        let filePath = "/tmp/test.txt"
        let entry = ClipboardEntry(timestamp: Date(), contentType: .file, fileURL: filePath)
        try await pasteService.preparePasteboard(for: entry)
        XCTAssertEqual(mockPasteboard.string(forType: .fileURL), "file://\(filePath)")
    }

    func testPasteURL_WritesToPasteboard() async throws {
        let url = "https://google.com"
        let entry = ClipboardEntry(timestamp: Date(), contentType: .url, plainTextContent: Data(url.utf8))
        try await pasteService.preparePasteboard(for: entry)
        XCTAssertEqual(mockPasteboard.string(forType: .URL), url)
        XCTAssertEqual(mockPasteboard.string(forType: .string), url)
    }

    func testPasteRTF_WritesToPasteboard() async throws {
        let rtf = Data("rtf".utf8)
        let txt = Data("txt".utf8)
        let entry = ClipboardEntry(timestamp: Date(), contentType: .rtf, plainTextContent: txt, richTextContent: rtf)
        try await pasteService.preparePasteboard(for: entry)
        XCTAssertEqual(mockPasteboard.data(forType: .rtf), rtf)
        XCTAssertEqual(mockPasteboard.string(forType: .string), "txt")
    }

    func testSimulatePaste_RespectsSettings() async {
        let settings = SettingsManager.shared
        let originalValue = settings.simulatePasteEnabled
        settings.simulatePasteEnabled = false
        await pasteService.simulatePaste()
        settings.simulatePasteEnabled = originalValue
    }
}
