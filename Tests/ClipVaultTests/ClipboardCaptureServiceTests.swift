//
//  ClipboardCaptureServiceTests.swift
//  ClipVaultTests
//
//  Created by ClipVault.
//

import XCTest
@testable import ClipVault

final class ClipboardCaptureServiceTests: XCTestCase {
    
    private var dbManager: DatabaseManager!
    private var encryptionService: EncryptionService!
    private var repository: ClipboardRepository!
    private var mockPasteboard: MockPasteboard!
    private var monitor: PasteboardMonitor!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        dbManager = try DatabaseManager(path: ":memory:")
        encryptionService = try EncryptionService()
        repository = ClipboardRepository(dbManager: dbManager, encryptionService: encryptionService)
        mockPasteboard = MockPasteboard()
        monitor = PasteboardMonitor(pasteboard: mockPasteboard, pollInterval: 0.05) // Fast poll for tests
    }
    
    override func tearDownWithError() throws {
        dbManager = nil
        encryptionService = nil
        repository = nil
        mockPasteboard = nil
        monitor = nil
        try super.tearDownWithError()
    }
    
    func testCaptureText_StoresEncryptedEntry() async throws {
        // Arrange
        let service = ClipboardCaptureService(
            monitor: monitor,
            repository: repository,
            pasteboard: mockPasteboard,
            workspaceAppIdentifier: { "com.apple.Terminal" }
        )
        
        await service.start()
        
        // Act
        mockPasteboard.simulateCopy(string: "Secret password")
        
        // Give the pipeline time to process the stream
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Assert
        let entries = try repository.fetchAll()
        XCTAssertEqual(entries.count, 1)
        
        let captured = try XCTUnwrap(entries.first)
        XCTAssertEqual(captured.contentType, "text")
        XCTAssertEqual(captured.sourceApplication, "com.apple.Terminal")
        
        let plainText = try XCTUnwrap(captured.plainTextContent)
        XCTAssertEqual(String(data: plainText, encoding: .utf8), "Secret password")
        
        let metadata = try XCTUnwrap(captured.metadata)
        XCTAssertEqual(String(data: metadata, encoding: .utf8), "{\"app\":\"com.apple.Terminal\"}")
        
        await service.stop()
    }
    
    func testCaptureImage_GeneratesThumbnailAndStores() async throws {
        // Arrange
        let service = ClipboardCaptureService(
            monitor: monitor,
            repository: repository,
            pasteboard: mockPasteboard,
            workspaceAppIdentifier: { "com.apple.Photos" }
        )
        
        // Create a fake 100x100 image
        let image = NSImage(size: NSSize(width: 100, height: 100))
        image.lockFocus()
        NSColor.red.setFill()
        NSRect(x: 0, y: 0, width: 100, height: 100).fill()
        image.unlockFocus()
        
        mockPasteboard.types = [.tiff]
        let tiffData = try XCTUnwrap(image.tiffRepresentation)
        
        await service.start()
        
        mockPasteboard.simulateCopy(data: tiffData, type: .tiff)
        
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let entries = try repository.fetchAll()
        XCTAssertEqual(entries.count, 1)
        
        let captured = try XCTUnwrap(entries.first)
        XCTAssertEqual(captured.contentType, "image")
        XCTAssertNotNil(captured.imageData)
        
        await service.stop()
    }
}
