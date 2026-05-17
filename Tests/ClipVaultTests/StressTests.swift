//
//  StressTests.swift
//  ClipVaultTests
//

import XCTest
@testable import ClipVault

final class StressTests: XCTestCase {
    
    private var dbManager: DatabaseManager!
    private var repository: ClipboardRepository!
    private var encryptionService: EncryptionService!
    private var keychainManager: KeychainManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        dbManager = try DatabaseManager(path: ":memory:")
        encryptionService = try EncryptionService()
        keychainManager = KeychainManager(service: "com.clipvault.test.stress.\(UUID().uuidString)")
        repository = ClipboardRepository(
            dbManager: dbManager,
            encryptionService: encryptionService,
            keychainManager: keychainManager
        )
    }
    
    override func tearDownWithError() throws {
        try? keychainManager.deleteKey()
        dbManager = nil
        repository = nil
        encryptionService = nil
        keychainManager = nil
        try super.tearDownWithError()
    }
    
    func testRapidSaves_MaintainsIntegrity() throws {
        let count = 100
        for i in 0..<count {
            var entry = ClipboardEntry(timestamp: Date(), contentType: "text", plainTextContent: Data("Test \(i)".utf8))
            try repository.save(&entry)
        }
        
        let all = try repository.fetchAll()
        XCTAssertEqual(all.count, count)
    }
    
    func testMassiveContent_SavesCorrectly() throws {
        // 10MB of text
        let massiveString = String(repeating: "A", count: 10 * 1024 * 1024)
        var entry = ClipboardEntry(timestamp: Date(), contentType: "text", plainTextContent: Data(massiveString.utf8))
        
        // This should trigger Vault storage
        try repository.save(&entry)
        
        let fetched = try repository.fetchAll().first!
        XCTAssertTrue(fetched.isVaultStored)
        XCTAssertNotNil(fetched.fileURL)
    }
}
