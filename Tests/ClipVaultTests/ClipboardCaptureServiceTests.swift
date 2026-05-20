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
    
    private var keychainManager: MockKeychainManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        dbManager = try DatabaseManager(path: ":memory:")
        encryptionService = try EncryptionService()
        keychainManager = MockKeychainManager()
        
        repository = ClipboardRepository(
            dbManager: dbManager, 
            encryptionService: encryptionService,
            keychainManager: keychainManager
        )
        
        mockPasteboard = MockPasteboard()
        monitor = PasteboardMonitor(pasteboard: mockPasteboard, pollInterval: 0.05) // Fast poll for tests
    }
    
    override func tearDownWithError() throws {
        
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
            pasteboard: mockPasteboard
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
        
        XCTAssertEqual(captured.contentType, .text)
        XCTAssertNotNil(captured.sourceApplication)
        
        let plainText = try XCTUnwrap(captured.plainTextContent)
        XCTAssertEqual(String(data: plainText, encoding: .utf8), "Secret password")
        
        let metadata = try XCTUnwrap(captured.metadata)
        let metadataString = String(data: metadata, encoding: .utf8) ?? ""
        XCTAssertTrue(metadataString.contains("\"isRemote\":false"))
        
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
        XCTAssertEqual(captured.contentType, .croppedImage)
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
        while (entries.isEmpty || entries.first?.contentType != .rtf) && Date().timeIntervalSince(startTime) < 1.0 {
            try await Task.sleep(nanoseconds: 50_000_000)
            entries = try repository.fetchAll()
        }
        
        XCTAssertEqual(entries.count, 1)
        let captured = try repository.decryptContent(for: entries.first!)
        XCTAssertEqual(captured.contentType, .rtf)
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

    func testCaptureUnknown_DoesNotStore() async throws {
        let service = ClipboardCaptureService(
            monitor: monitor,
            repository: repository,
            pasteboard: mockPasteboard
        )
        await service.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Act: Simulate unknown copy
        mockPasteboard.types = [NSPasteboard.PasteboardType("com.example.unknown")]
        mockPasteboard.changeCount += 1
        
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Assert: No entries should be saved
        let entries = try repository.fetchAll()
        XCTAssertEqual(entries.count, 0)
        
        await service.stop()
    }

    func testCaptureURL_StoresText() async throws {
        let service = ClipboardCaptureService(
            monitor: monitor,
            repository: repository,
            pasteboard: mockPasteboard
        )
        await service.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Act: Simulate URL copy
        let urlString = "https://apple.com"
        mockPasteboard.types = [.URL, .string]
        mockPasteboard.simulateCopy(string: urlString, type: .URL)
        mockPasteboard.simulateCopy(string: urlString, type: .string)
        
        let startTime = Date()
        var entries = try repository.fetchAll()
        while (entries.isEmpty || entries.first?.contentType != .url) && Date().timeIntervalSince(startTime) < 1.0 {
            try await Task.sleep(nanoseconds: 50_000_000)
            entries = try repository.fetchAll()
        }
        
        XCTAssertEqual(entries.count, 1)
        let captured = try repository.decryptContent(for: entries.first!)
        XCTAssertEqual(captured.contentType, .url)
        
        await service.stop()
    }

    func testCaptureHTML_StoresRichText() async throws {
        let service = ClipboardCaptureService(
            monitor: monitor,
            repository: repository,
            pasteboard: mockPasteboard
        )
        await service.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Act: Simulate HTML copy
        let htmlData = "<b>Hello</b>".data(using: .utf8)!
        mockPasteboard.types = [.html]
        mockPasteboard.simulateCopy(data: htmlData, type: .html)
        
        let startTime = Date()
        var entries = try repository.fetchAll()
        while (entries.isEmpty || entries.first?.contentType != .html) && Date().timeIntervalSince(startTime) < 1.0 {
            try await Task.sleep(nanoseconds: 50_000_000)
            entries = try repository.fetchAll()
        }
        
        XCTAssertEqual(entries.count, 1)
        let captured = try repository.decryptContent(for: entries.first!)
        XCTAssertEqual(captured.contentType, .html)
        XCTAssertNotNil(captured.richTextContent)
        
        await service.stop()
    }

    func testCapture_ConcealedContent_IsIgnored() async throws {
        let service = ClipboardCaptureService(
            monitor: monitor,
            repository: repository,
            pasteboard: mockPasteboard
        )
        await service.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Act: Simulate concealed content
        let concealedType = NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")
        mockPasteboard.types = [concealedType, .string]
        mockPasteboard.simulateCopy(string: "Sensitive Password")
        
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Assert: No entries should be saved
        let entries = try repository.fetchAll()
        XCTAssertEqual(entries.count, 0)
        
        await service.stop()
    }

    func testInit_DefaultArguments() {
        let _ = ClipboardCaptureService(
            monitor: monitor,
            repository: repository,
            pasteboard: mockPasteboard
        )
    }
}
