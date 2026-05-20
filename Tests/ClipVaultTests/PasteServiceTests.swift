//
//  PasteServiceTests.swift
//  ClipVaultTests
//

import XCTest
@testable import ClipVault

final class PasteServiceTests: XCTestCase {
    
    private var mockPasteboard: MockPasteboard!
    private var pasteService: PasteService!
    
    override func setUp() {
        super.setUp()
        mockPasteboard = MockPasteboard()
        pasteService = PasteService(pasteboard: mockPasteboard)
    }
    
    func testPasteText_WritesToPasteboard() async throws {
        // Arrange
        let entry = ClipboardEntry(timestamp: Date(), contentType: .text, plainTextContent: Data("Hello Paste".utf8))
        
        // Act
        try await pasteService.preparePasteboard(for: entry)
        
        // Assert
        XCTAssertEqual(mockPasteboard.string(forType: .string), "Hello Paste")
    }
    
    func testPasteImage_WritesToPasteboard() async throws {
        // Arrange
        let tiffData = Data([0x01, 0x02]) // Mock TIFF data
        let entry = ClipboardEntry(timestamp: Date(), contentType: .image, imageData: tiffData)
        
        // Act
        try await pasteService.preparePasteboard(for: entry)
        
        // Assert
        XCTAssertEqual(mockPasteboard.data(forType: .tiff), tiffData)
    }
    
    func testPasteFile_WritesToPasteboard() async throws {
        // Arrange
        let filePath = "/tmp/test.txt"
        let entry = ClipboardEntry(timestamp: Date(), contentType: .file, fileURL: filePath)
        
        // Act
        try await pasteService.preparePasteboard(for: entry)
        
        // Assert
        XCTAssertEqual(mockPasteboard.string(forType: .fileURL), "file://\(filePath)")
    }

    func testSimulatePaste_RespectsSettings() async {
        // Arrange
        let settings = SettingsManager.shared
        let originalValue = settings.simulatePasteEnabled
        
        // Act: Disable simulation
        settings.simulatePasteEnabled = false
        await pasteService.simulatePaste() // Should return early without crash/delay
        
        // Restore
        settings.simulatePasteEnabled = originalValue
    }
}
