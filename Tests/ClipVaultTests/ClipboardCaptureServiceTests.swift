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
        let capturedRaw = try XCTUnwrap(fetchedEntries.first)
        let captured = try repository.decryptContent(for: capturedRaw)
        
        XCTAssertEqual(captured.contentType, "text")
        XCTAssertEqual(captured.sourceApplication, "com.apple.Terminal")
        
        let plainText = try XCTUnwrap(captured.plainTextContent)
        XCTAssertEqual(String(data: plainText, encoding: .utf8), "Secret password")
        
        let metadata = try XCTUnwrap(captured.metadata)
        XCTAssertEqual(String(data: metadata, encoding: .utf8), "{\"app\":\"com.apple.Terminal\",\"isRemote\":false}")
        
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
        let capturedRaw = try XCTUnwrap(fetchedEntries.first)
        let captured = try repository.decryptContent(for: capturedRaw)
        XCTAssertEqual(captured.contentType, "image")
        XCTAssertNotNil(captured.imageData)
        
        await service.stop()
    }

    func testCapture_ConsecutiveDeduplication() async throws {
        let service = ClipboardCaptureService(
            monitor: monitor,
            repository: repository,
            pasteboard: mockPasteboard,
            workspaceAppIdentifier: { "com.apple.Terminal" }
        )
        await service.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Act: Copy same content twice
        mockPasteboard.simulateCopy(string: "Same Content")
        try await Task.sleep(nanoseconds: 200_000_000)
        
        mockPasteboard.simulateCopy(string: "Same Content")
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Assert: Only 1 entry should be saved
        let entries = try repository.fetchAll()
        XCTAssertEqual(entries.count, 1)
        
        await service.stop()
    }

    func testCapture_RemoteItem_SetsIsRemoteFlag() async throws {
        let service = ClipboardCaptureService(
            monitor: monitor,
            repository: repository,
            pasteboard: mockPasteboard,
            workspaceAppIdentifier: { "com.apple.Terminal" }
        )
        await service.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Act: Simulate remote copy
        mockPasteboard.simulateCopy(string: "From iPhone", isRemote: true)
        
        let startTime = Date()
        var entries = try repository.fetchAll()
        while entries.isEmpty && Date().timeIntervalSince(startTime) < 1.0 {
            try await Task.sleep(nanoseconds: 50_000_000)
            entries = try repository.fetchAll()
        }
        
        XCTAssertEqual(entries.count, 1)
        XCTAssertTrue(entries.first?.isRemote ?? false)
        
        await service.stop()
    }

    func testCapture_RichText_StoresRichTextContent() async throws {
        let service = ClipboardCaptureService(
            monitor: monitor,
            repository: repository,
            pasteboard: mockPasteboard,
            workspaceAppIdentifier: { "com.apple.TextEdit" }
        )
        await service.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Act: Simulate RTF copy
        let rtfData = "{\\rtf1\\ansi\\deff0 {\\fonttbl {\\f0 Courier;}} \\f0\\fs24 Hello World}".data(using: .utf8)!
        mockPasteboard.simulateCopy(data: rtfData, type: .rtf)
        
        let startTime = Date()
        var entries = try repository.fetchAll()
        while (entries.isEmpty || entries.first?.contentType != "rtf") && Date().timeIntervalSince(startTime) < 1.0 {
            try await Task.sleep(nanoseconds: 50_000_000)
            entries = try repository.fetchAll()
        }
        
        XCTAssertEqual(entries.count, 1)
        let captured = try repository.decryptContent(for: entries.first!)
        XCTAssertEqual(captured.contentType, "rtf")
        XCTAssertNotNil(captured.richTextContent)
        
        await service.stop()
    }

    func testCapture_UnknownType_DoesNotStore() async throws {
        let service = ClipboardCaptureService(
            monitor: monitor,
            repository: repository,
            pasteboard: mockPasteboard
        )
        await service.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Act: Simulate copy with unknown type (no types on pasteboard)
        mockPasteboard.clearContents()
        mockPasteboard.types = []
        mockPasteboard.changeCount += 1
        
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Assert: No entries should be saved
        let entries = try repository.fetchAll()
        XCTAssertEqual(entries.count, 0)
        
        await service.stop()
    }
}
