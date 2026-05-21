//
//  ViewModelPaginationTests.swift
//  ClipVaultTests
//

import XCTest
@testable import ClipVault

@MainActor
final class ViewModelPaginationTests: XCTestCase {
    private var viewModel: ClipboardViewModel!
    private var repository: ClipboardRepository!
    private var dbManager: DatabaseManager!
    
    override func setUpWithError() throws {
        dbManager = DatabaseManager(inMemory: true)
        repository = ClipboardRepository(dbManager: dbManager)
        viewModel = ClipboardViewModel(repository: repository)
    }
    
    func testLoadMore_FetchesNextPage() async throws {
        // Arrange: Create 60 entries (pageSize is 50)
        for i in 1...60 {
            var entry = ClipboardEntry(contentType: .text, plainTextContent: "Entry \(i)".data(using: .utf8))
            try repository.save(&entry)
        }
        
        // Act: Initial load
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(viewModel.entries.count, 50)
        
        // Act: Load more
        viewModel.loadMore()
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Assert
        XCTAssertEqual(viewModel.entries.count, 60)
    }
    
    func testSearch_UpdatesResults() async throws {
        // Arrange
        var entry1 = ClipboardEntry(contentType: .text, plainTextContent: "Apple".data(using: .utf8))
        var entry2 = ClipboardEntry(contentType: .text, plainTextContent: "Banana".data(using: .utf8))
        try repository.save(&entry1)
        try repository.save(&entry2)
        
        // Act
        viewModel.searchQuery = "App"
        try await Task.sleep(nanoseconds: 400_000_000) // Wait for debounce
        
        // Assert
        XCTAssertEqual(viewModel.entries.count, 1)
        XCTAssertEqual(viewModel.entries.first?.plainTextSearchContent, "Apple")
    }
}
