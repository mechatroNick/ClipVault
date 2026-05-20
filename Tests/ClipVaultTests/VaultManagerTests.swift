//
//  VaultManagerTests.swift
//  ClipVaultTests
//

import XCTest
@testable import ClipVault

final class VaultManagerTests: XCTestCase {
    
    private var originalVaultPath: String!
    private var testVaultPath: String!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        originalVaultPath = SettingsManager.shared.vaultRootPath
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        testVaultPath = tempDir.path
        SettingsManager.shared.vaultRootPath = testVaultPath
    }
    
    override func tearDownWithError() throws {
        SettingsManager.shared.vaultRootPath = originalVaultPath
        if FileManager.default.fileExists(atPath: testVaultPath) {
            try? FileManager.default.removeItem(atPath: testVaultPath)
        }
        try super.tearDownWithError()
    }
    
    func testVaultManagerInit_CreatesDirectorySafely() throws {
        XCTAssertFalse(FileManager.default.fileExists(atPath: testVaultPath), "Test directory should not exist yet")
        
        // Force evaluation of the shared instance or call ensure directly
        // We can't re-init the singleton easily, but we can call ensureVaultExists
        // which has the exact same code
        let vaultManager = VaultManager.shared
        try vaultManager.ensureVaultExists()
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: testVaultPath), "VaultManager should create the directory")
        
        // Create a dummy file to ensure it's not destroyed by a second call
        let dummyFile = URL(fileURLWithPath: testVaultPath).appendingPathComponent("dummy.txt")
        try "test".write(to: dummyFile, atomically: true, encoding: .utf8)
        
        // Call it again
        try vaultManager.ensureVaultExists()
        
        // Assert it didn't crash and the file is still there
        XCTAssertTrue(FileManager.default.fileExists(atPath: dummyFile.path), "ensureVaultExists should be non-destructive")
    }
}
