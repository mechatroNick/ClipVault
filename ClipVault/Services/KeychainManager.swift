import Foundation
import CryptoKit
import Security

enum KeychainError: LocalizedError {
    case invalidKeyData
    case keychainError(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .invalidKeyData:
            return "The data retrieved from the keychain is not a valid 256-bit SymmetricKey."
        case .keychainError(let status):
            return "Keychain operation failed with OSStatus: \(status)"
        }
    }
}

final class KeychainManager {
    private let service: String
    private let account = "encryption-key"
    
    init(service: String = "com.clipvault.encryption") {
        self.service = service
    }
    
    func generateAndStoreKey() throws -> SymmetricKey {
        let key = SymmetricKey(size: .bits256)
        try storeKey(key)
        return key
    }
    
    func storeKey(_ key: SymmetricKey) throws {
        let keyData = key.withUnsafeBytes { Data($0) }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let attributesToUpdate: [String: Any] = [
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        
        if status == errSecItemNotFound {
            var newQuery = query
            newQuery[kSecValueData as String] = keyData
            newQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked
            let addStatus = SecItemAdd(newQuery as CFDictionary, nil)
            if addStatus != errSecSuccess {
                throw KeychainError.keychainError(addStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.keychainError(status)
        }
    }
    
    func retrieveKey() throws -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecItemNotFound {
            return nil
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.keychainError(status)
        }
        
        guard let keyData = dataTypeRef as? Data else {
            throw KeychainError.invalidKeyData
        }
        
        guard keyData.count == 32 else { // 256 bits
            throw KeychainError.invalidKeyData
        }
        
        return SymmetricKey(data: keyData)
    }
    
    func deleteKey() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.keychainError(status)
        }
    }
}
