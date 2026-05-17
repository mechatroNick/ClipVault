//
//  KeychainManagerTests.swift
//  ClipVaultTests
//
//  Created by ClipVault.
//

import XCTest
@testable import ClipVault
import CryptoKit
import Security

/// Verifies KeychainManager encryption key storage, retrieval, deletion, generation,
/// and error handling using unique service names per test for isolation.
final class KeychainManagerTests: XCTestCase {

    private var manager: KeychainManager!
    private var service: String!

    override func setUpWithError() throws {
        try super.setUpWithError()

        let isCI = ProcessInfo.processInfo.environment["CI"] == "true"
        try XCTSkipIf(isCI, "Keychain access requires GUI authorization; skipped in CI environments")

        service = "com.clipvault.test.\(UUID().uuidString)"
        manager = KeychainManager(service: service)
    }

    override func tearDownWithError() throws {
        try? manager.deleteKey()
        manager = nil
        service = nil
        try super.tearDownWithError()
    }

    // MARK: - Key Generation

    /// Verifies that generateAndStoreKey produces a 256-bit symmetric key.
    func testGenerateKey_Creates256BitKey() throws {
        // Act
        let key = try manager.generateAndStoreKey()

        // Assert
        XCTAssertEqual(key.bitCount, 256, "Generated key must be AES-256 (256 bits)")
    }

    // MARK: - Store & Retrieve Round-Trip

    /// Stores a SymmetricKey, retrieves it, and verifies the raw Data matches byte-for-byte.
    func testStoreAndRetrieve_RoundTrip() throws {
        // Arrange
        let key = SymmetricKey(size: .bits256)
        let originalData = key.withUnsafeBytes { Data($0) }

        // Act
        try manager.storeKey(key)
        let retrieved = try XCTUnwrap(try manager.retrieveKey(), "Retrieved key should not be nil after store")

        // Assert
        let retrievedData = retrieved.withUnsafeBytes { Data($0) }
        XCTAssertEqual(originalData, retrievedData, "Round-tripped key data must be byte-identical")
    }

    // MARK: - Retrieve When Empty

    /// retrieveKey returns nil when no key has ever been stored on this service.
    func testRetrieve_WhenNoKeyStored_ReturnsNil() throws {
        // Act
        let result = try manager.retrieveKey()

        // Assert
        XCTAssertNil(result, "retrieveKey must return nil when no key exists for this service")
    }

    // MARK: - Deletion

    /// Store a key, delete it, then verify retrieve returns nil.
    func testDelete_RemovesKey() throws {
        // Arrange
        let key = SymmetricKey(size: .bits256)
        try manager.storeKey(key)

        // Act
        try manager.deleteKey()

        // Assert
        let result = try manager.retrieveKey()
        XCTAssertNil(result, "retrieveKey must return nil after deleteKey")
    }

    /// deleteKey on a clean service should not throw (no-op).
    func testDelete_WhenNoKeyExists_DoesNotThrow() throws {
        // Act & Assert — must not throw
        XCTAssertNoThrow(try manager.deleteKey(), "deleteKey on empty service must be a no-op")
    }

    // MARK: - Regeneration Recovery

    /// When no key exists, generateAndStoreKey succeeds and the new key is retrievable.
    func testRegenerate_WhenKeyMissing() throws {
        // Arrange: verify no key exists
        let missing = try manager.retrieveKey()
        XCTAssertNil(missing, "Precondition: no key should exist on clean service")

        // Act
        let newKey = try manager.generateAndStoreKey()

        // Assert
        XCTAssertEqual(newKey.bitCount, 256)
        let retrieved = try XCTUnwrap(try manager.retrieveKey())
        let newData = newKey.withUnsafeBytes { Data($0) }
        let retrievedData = retrieved.withUnsafeBytes { Data($0) }
        XCTAssertEqual(newData, retrievedData, "Regenerated key must be retrievable")
    }

    // MARK: - Store Overwrite

    /// Storing a second key replaces the first. retrieveKey returns only the latest key.
    func testStoreOverwrite_UpdatesKey() throws {
        // Arrange
        let keyA = SymmetricKey(size: .bits256)
        let keyB = SymmetricKey(size: .bits256)
        let dataB = keyB.withUnsafeBytes { Data($0) }

        // Ensure A and B are different (cryptographically near-certain)
        XCTAssertNotEqual(
            keyA.withUnsafeBytes { Data($0) },
            dataB,
            "Two independent SymmetricKey instances should have different raw data"
        )

        try manager.storeKey(keyA)

        // Act
        try manager.storeKey(keyB)
        let retrieved = try XCTUnwrap(try manager.retrieveKey())

        // Assert
        let retrievedData = retrieved.withUnsafeBytes { Data($0) }
        XCTAssertEqual(retrievedData, dataB, "retrieveKey must return key B after overwrite")
        XCTAssertNotEqual(
            retrievedData,
            keyA.withUnsafeBytes { Data($0) },
            "retrieveKey must NOT return the overwritten key A"
        )
    }

    // MARK: - Cross-Instance Persistence

    /// A key stored by one KeychainManager instance is retrievable by a new instance
    /// using the same service name.
    func testPersistence_AcrossInstances() throws {
        // Arrange: use first instance to generate and store
        let key = try manager.generateAndStoreKey()
        let originalData = key.withUnsafeBytes { Data($0) }

        // Act: create a second instance with the same service name
        let secondManager = KeychainManager(service: service)
        let retrieved = try XCTUnwrap(try secondManager.retrieveKey())

        // Assert
        let retrievedData = retrieved.withUnsafeBytes { Data($0) }
        XCTAssertEqual(retrievedData, originalData,
                       "New instance on same service must retrieve the same key data")
    }

    // MARK: - Unique Keys Per Service

    /// generateAndStoreKey on two different services produces distinct keys.
    func testGenerateKey_ProducesUniqueKeys() throws {
        // Arrange
        let service1 = "com.clipvault.test.\(UUID().uuidString)"
        let service2 = "com.clipvault.test.\(UUID().uuidString)"
        let manager1 = KeychainManager(service: service1)
        let manager2 = KeychainManager(service: service2)
        defer {
            try? manager1.deleteKey()
            try? manager2.deleteKey()
        }

        // Act
        let key1 = try manager1.generateAndStoreKey()
        let key2 = try manager2.generateAndStoreKey()

        // Assert
        let data1 = key1.withUnsafeBytes { Data($0) }
        let data2 = key2.withUnsafeBytes { Data($0) }
        XCTAssertNotEqual(data1, data2,
                          "Keys generated for different services must be unique")
    }

    // MARK: - Malformed Keychain Data

    /// When raw data exists in the Keychain that is not a valid SymmetricKey,
    /// retrieveKey throws KeychainError.invalidKeyData.
    func testInvalidKeyData_ThrowsError() throws {
        // Arrange: inject malformed data directly into the Keychain
        let malformedData = Data((0..<16).map { UInt8($0) })  // 128 bits — too short for SymmetricKey(size: .bits256)
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "encryption-key",
            kSecValueData as String: malformedData,
        ]
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            XCTFail("Failed to inject malformed keychain data (OSStatus: \(addStatus))")
            return
        }

        // Clean up the injected item even if the test fails
        defer {
            let delQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: "encryption-key",
            ]
            SecItemDelete(delQuery as CFDictionary)
        }

        // Act & Assert
        XCTAssertThrowsError(try manager.retrieveKey()) { error in
            guard let keychainError = error as? KeychainError,
                  case .invalidKeyData = keychainError else {
                XCTFail("Expected KeychainError.invalidKeyData, got \(error)")
                return
            }
        }
    }
}
