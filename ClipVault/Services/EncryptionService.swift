//
//  EncryptionService.swift
//  ClipVault
//
//  Created by ClipVault.
//

import Foundation
import CryptoKit

/// Encrypted package storing AES-GCM components separately.
/// Nonce: 12 bytes, Tag: 16 bytes. Combined format: nonce || ciphertext || tag
struct EncryptedPackage: Codable {
    var nonce: Data       // 12 bytes
    var ciphertext: Data  // variable
    var tag: Data         // 16 bytes

    var combined: Data { nonce + ciphertext + tag }

    init(nonce: Data, ciphertext: Data, tag: Data) {
        self.nonce = nonce
        self.ciphertext = ciphertext
        self.tag = tag
    }

    init(combined: Data) throws {
        guard combined.count >= 28 else {
            throw EncryptionError.invalidCombinedData
        }
        nonce = combined.prefix(12)
        tag = combined.suffix(16)
        ciphertext = combined.dropFirst(12).dropLast(16)
    }

    init(_ sealedBox: AES.GCM.SealedBox) {
        nonce = sealedBox.nonce.withUnsafeBytes { Data($0) }
        ciphertext = sealedBox.ciphertext
        tag = sealedBox.tag
    }
}

enum EncryptionError: LocalizedError {
    case invalidCombinedData
    case encryptionFailed
    case decryptionFailed
    case invalidKeySize

    var errorDescription: String? {
        switch self {
        case .invalidCombinedData:
            return "Combined data must be at least 28 bytes (12 nonce + 0+ ciphertext + 16 tag)"
        case .encryptionFailed:
            return "AES-GCM encryption failed"
        case .decryptionFailed:
            return "AES-GCM decryption failed — data may be tampered or key incorrect"
        case .invalidKeySize:
            return "SymmetricKey must be 256 bits (32 bytes) for AES-256-GCM"
        }
    }
}

struct EncryptionService {
    /// Encrypts plaintext using AES-256-GCM with a randomly generated nonce.
    /// - Parameters:
    ///   - plaintext: The data to encrypt (may be empty)
    ///   - key: 256-bit SymmetricKey
    /// - Returns: EncryptedPackage with nonce, ciphertext, and authentication tag
    func encrypt(plaintext: Data, using key: SymmetricKey) throws -> EncryptedPackage {
        guard key.bitCount == 256 else { throw EncryptionError.invalidKeySize }
        let nonce = AES.GCM.Nonce()
        let sealedBox = try AES.GCM.seal(plaintext, using: key, nonce: nonce)
        return EncryptedPackage(sealedBox)
    }

    /// Decrypts an EncryptedPackage using AES-256-GCM.
    /// - Parameters:
    ///   - package: The encrypted package containing nonce, ciphertext, and tag
    ///   - key: 256-bit SymmetricKey
    /// - Returns: Decrypted plaintext data
    func decrypt(package: EncryptedPackage, using key: SymmetricKey) throws -> Data {
        guard key.bitCount == 256 else { throw EncryptionError.invalidKeySize }
        let nonce = try AES.GCM.Nonce(data: package.nonce)
        let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: package.ciphertext, tag: package.tag)
        return try AES.GCM.open(sealedBox, using: key)
    }
}
