//
//  ClipboardViewModelTests.swift
//  ClipVaultTests
//

import XCTest
@testable import ClipVault

@MainActor
final class ClipboardViewModelTests: XCTestCase {
    
    private var viewModel: ClipboardViewModel!
    private var repository: ClipboardRepository!
    private var dbManager: DatabaseManager!
    private var encryptionService: EncryptionService!
    private var keychainManager: KeychainManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        dbManager = try DatabaseManager(path: ":memory:")
        encryptionService = try EncryptionService()
        keychainManager = KeychainManager(service: "com.clipvault.test.viewmodel.\(UUID().uuidString)")
        repository = ClipboardRepository(
            dbManager: dbManager,
            encryptionService: encryptionService,
            keychainManager: keychainManager
        )
        viewModel = ClipboardViewModel(repository: repository)
    }
    
    override func tearDownWithError() throws {
        try? keychainManager.deleteKey()
        viewModel = nil
        repository = nil
        dbManager = nil
        encryptionService = nil
        keychainManager = nil
        try super.tearDownWithError()
    }
    
    func testInitialState_IsEmpty() {
        XCTAssertTrue(viewModel.entries.isEmpty)
        XCTAssertEqual(viewModel.searchQuery, "")
        XCTAssertNil(viewModel.selectedIndex)
    }
    
    func testObservation_UpdatesEntriesAutomatically() async throws {
        // Act
        var entry = ClipboardEntry(timestamp: Date(), contentType: "text", plainTextContent: Data("Secret".utf8))
        try repository.save(&entry)
        
        // Assert: Wait for observation
        let startTime = Date()
        while viewModel.entries.isEmpty && Date().timeIntervalSince(startTime) < 1.0 {
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        
        XCTAssertEqual(viewModel.entries.count, 1)
        XCTAssertEqual(viewModel.entries.first?.plainTextSearchContent, "Secret")
    }
    
    func testSearchQuery_UpdatesFilteredEntries() async throws {
        // Arrange
        var entry1 = ClipboardEntry(timestamp: Date(), contentType: "text", plainTextContent: Data("Hello".utf8))
        var entry2 = ClipboardEntry(timestamp: Date().addingTimeInterval(1), contentType: "text", plainTextContent: Data("World".utf8))
        try repository.save(&entry1)
        try repository.save(&entry2)
        
        // Wait for observation to pick up changes
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Act
        viewModel.searchQuery = "Hello"
        
        // Assert
        // Note: Real implementation will likely use GRDB ValueObservation or similar.
        // For now we test the state machine.
        XCTAssertEqual(viewModel.entries.count, 1)
        XCTAssertEqual(viewModel.entries.first?.plainTextSearchContent, "Hello")
    }
}
