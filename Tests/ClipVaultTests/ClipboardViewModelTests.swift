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
        viewModel = ClipboardViewModel(repository: repository, pasteService: PasteService())
    }
    
    override func tearDownWithError() throws {
        
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
        var entry = ClipboardEntry(timestamp: Date(), contentType: .text, plainTextContent: Data("Secret".utf8))
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
        var entry1 = ClipboardEntry(timestamp: Date(), contentType: .text, plainTextContent: Data("Apple".utf8))
        var entry2 = ClipboardEntry(timestamp: Date(), contentType: .text, plainTextContent: Data("Banana".utf8))
        try repository.save(&entry1)
        try repository.save(&entry2)
        
        // Wait for initial observation
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(viewModel.entries.count, 2)
        
        // Act: Set search query
        viewModel.searchQuery = "App"
        
        // Assert: Result should NOT be filtered immediately due to debounce
        XCTAssertEqual(viewModel.entries.count, 2)
        
        // Wait for debounce (300ms + margin)
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Assert: Result should be filtered now
        XCTAssertEqual(viewModel.entries.count, 1)
        XCTAssertEqual(viewModel.entries.first?.plainTextSearchContent, "Apple")
    }
    
    func testMoveSelection_WrapsAround() {
        // Arrange
        viewModel.entries = [
            ClipboardEntry(timestamp: Date(), contentType: .text),
            ClipboardEntry(timestamp: Date(), contentType: .text),
            ClipboardEntry(timestamp: Date(), contentType: .text)
        ]
        
        // Act: Down from nil
        viewModel.moveSelection(direction: 1)
        XCTAssertEqual(viewModel.selectedIndex, 0)
        
        // Act: Down to last
        viewModel.moveSelection(direction: 1)
        viewModel.moveSelection(direction: 1)
        XCTAssertEqual(viewModel.selectedIndex, 2)
        
        // Act: Wrap around to first
        viewModel.moveSelection(direction: 1)
        XCTAssertEqual(viewModel.selectedIndex, 0)
        
        // Act: Up to last
        viewModel.moveSelection(direction: -1)
        XCTAssertEqual(viewModel.selectedIndex, 2)
    }

    func testLoadMoreEntries_SearchMode_LoadsAdditionalResults() async throws {
        // Arrange: Create 60 entries (pageSize is 50)
        for i in 1...60 {
            var entry = ClipboardEntry(timestamp: Date().addingTimeInterval(TimeInterval(i)), contentType: .text, plainTextContent: Data("Match \(i)".utf8))
            try repository.save(&entry)
        }
        
        // Act: Start search
        viewModel.searchQuery = "Match"
        try await Task.sleep(nanoseconds: 500_000_000) // Wait for debounce
        
        // Assert: Initial page loaded
        XCTAssertEqual(viewModel.entries.count, 50)
        
        // Act: Load more
        viewModel.loadMoreEntries()
        
        // Assert: Wait for load
        let startTime = Date()
        while viewModel.entries.count < 60 && Date().timeIntervalSince(startTime) < 1.0 {
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        
        XCTAssertEqual(viewModel.entries.count, 60)
    }

    func testDeleteEntry_RemovesFromDatabaseAndList() async throws {
        // Arrange
        var entry = ClipboardEntry(timestamp: Date(), contentType: .text, plainTextContent: Data("To Delete".utf8))
        try repository.save(&entry)
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(viewModel.entries.count, 1)
        
        // Act
        viewModel.deleteEntry(at: 0)
        
        // Assert
        let startTime = Date()
        while !viewModel.entries.isEmpty && Date().timeIntervalSince(startTime) < 1.0 {
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        XCTAssertTrue(viewModel.entries.isEmpty)
        XCTAssertEqual(try repository.fetchAll().count, 0)
    }

    func testTogglePin_UpdatesDatabaseAndEntry() async throws {
        // Arrange
        var entry = ClipboardEntry(timestamp: Date(), contentType: .text, plainTextContent: Data("To Pin".utf8))
        try repository.save(&entry)
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertFalse(viewModel.entries[0].isPinned)
        
        // Act
        viewModel.togglePin(at: 0)
        
        // Assert: wait for update
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertTrue(viewModel.entries[0].isPinned)
        XCTAssertTrue(try repository.fetchAll()[0].isPinned)
    }

    func testCopyEntry_PreparesPasteboard() async throws {
        // Arrange
        let mockPasteboard = MockPasteboard()
        let pasteService = PasteService(pasteboard: mockPasteboard)
        let vm = ClipboardViewModel(repository: repository, pasteService: pasteService)
        
        var entry = ClipboardEntry(timestamp: Date(), contentType: .text, plainTextContent: Data("To Copy".utf8))
        try repository.save(&entry)
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Act
        vm.copyEntry(at: 0)
        
        // Assert: PreparePasteboard is async, but copyEntry launches it in a Task.
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(mockPasteboard.string(forType: .string), "To Copy")
    }
}
