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
    
    private var keychainManager: KeychainManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        dbManager = try DatabaseManager(path: ":memory:")
        encryptionService = try EncryptionService()
        
        let serviceName = "com.clipvault.test.capture.\(UUID().uuidString)"
        keychainManager = KeychainManager(service: serviceName)
        
        repository = ClipboardRepository(
            dbManager: dbManager, 
            encryptionService: encryptionService,
            keychainManager: keychainManager
        )
        
        mockPasteboard = MockPasteboard()
        monitor = PasteboardMonitor(pasteboard: mockPasteboard, pollInterval: 0.05) // Fast poll for tests
    }
    
    override func tearDownWithError() throws {
        try? keychainManager.deleteKey()
        dbManager = nil
        encryptionService = nil
        repository = nil
        keychainManager = nil
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
        
        // Wait for monitor's main thread setup to complete
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Act
        mockPasteboard.simulateCopy(string: "Secret password")
        
        // Assert: wait up to 1 second for the entry to appear in the repository
        let startTime = Date()
        var entries = try dbManager.fetchAll()
        while entries.isEmpty && Date().timeIntervalSince(startTime) < 1.0 {
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms
            entries = try dbManager.fetchAll()
        }

        XCTAssertEqual(entries.count, 1)

        let fetchedEntries = try repository.fetchAll()
        let captured = try XCTUnwrap(fetchedEntries.first)
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
        
        // Wait for monitor's main thread setup to complete
        try await Task.sleep(nanoseconds: 100_000_000)
        
        mockPasteboard.simulateCopy(data: tiffData, type: .tiff)
        
        // Assert: wait up to 5 seconds for the entry to appear in the repository
        let startTime = Date()
        var entries = try dbManager.fetchAll()
        while entries.isEmpty && Date().timeIntervalSince(startTime) < 5.0 {
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms
            entries = try dbManager.fetchAll()
        }

        if entries.isEmpty {
            print("DEBUG: entries is empty after 5.0 seconds.")
            print("DEBUG: mockPasteboard types: \(String(describing: mockPasteboard.types))")
            print("DEBUG: mockPasteboard changeCount: \(mockPasteboard.changeCount)")
        }

        XCTAssertEqual(entries.count, 1)

        let fetchedEntries = try repository.fetchAll()
        let captured = try XCTUnwrap(fetchedEntries.first)
        XCTAssertEqual(captured.contentType, "image")
        XCTAssertNotNil(captured.imageData)
        
        await service.stop()
    }
}
