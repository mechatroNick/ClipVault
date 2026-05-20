//
//  MockKeychainManager.swift
//  ClipVaultTests
//

import CryptoKit
@testable import ClipVault

final class MockKeychainManager: KeychainProtocol {
    private var key: SymmetricKey?
    
    func generateAndStoreKey() throws -> SymmetricKey {
        let newKey = SymmetricKey(size: .bits256)
        key = newKey
        return newKey
    }
    
    func storeKey(_ key: SymmetricKey) throws {
        self.key = key
    }
    
    func retrieveKey() throws -> SymmetricKey? {
        return key
    }
    
    func deleteKey() throws {
        key = nil
    }
}
