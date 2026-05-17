//
//  EncryptionServiceTests.swift
//  ClipVaultTests
//
//  Created by ClipVault.
//

import XCTest
@testable import ClipVault
import CryptoKit

/// Verifies AES-256-GCM encryption/decryption using NIST CAVP test vectors.
final class EncryptionServiceTests: XCTestCase {

    private var service: EncryptionService!

    override func setUpWithError() throws {
        try super.setUpWithError()
        service = EncryptionService()
    }

    override func tearDownWithError() throws {
        service = nil
        try super.tearDownWithError()
    }

    // MARK: - Helpers

    /// Converts a lowercase hex string to Data.
    private func hexToData(_ hex: String) -> Data {
        guard hex.count % 2 == 0 else { return Data() }
        var data = Data(capacity: hex.count / 2)
        var index = hex.startIndex
        while index < hex.endIndex {
            let nextIndex = hex.index(index, offsetBy: 2)
            guard let byte = UInt8(hex[index..<nextIndex], radix: 16) else {
                return Data()
            }
            data.append(byte)
            index = nextIndex
        }
        return data
    }

    // MARK: - NIST CAVP Vector 1 (Empty plaintext, empty AAD — GMAC mode)
    // Key: b52c505a37d78eda5dd34f20c22540ea1b58963cf8e5bf8ffa85f9f2492505b4
    // IV:  516c33929df5a3284ff463d7
    // PT:  (empty)
    // AAD: (empty)
    // CT:  (empty)
    // Tag: bdc1ac884d332457a1d2664f168c76f0

    private func vector1Key() -> SymmetricKey {
        SymmetricKey(data: hexToData("b52c505a37d78eda5dd34f20c22540ea1b58963cf8e5bf8ffa85f9f2492505b4"))
    }

    private func vector1Nonce() throws -> AES.GCM.Nonce {
        try AES.GCM.Nonce(data: hexToData("516c33929df5a3284ff463d7"))
    }

    // MARK: - NIST CAVP Vector 2 (51-byte plaintext, 48-byte AAD)
    // Key: 463b412911767d57a0b33969e674ffe7845d313b88c6fe312f3d724be68e1fca
    // IV:  611ce6f9a6880750de7da6cb
    // PT:  e7d1dcf668e2876861940e012fe52a98dacbd78ab63c08842cc9801ea581682ad54af0c34d0d7f6f59e8ee0bf4900e0fd85042
    // AAD: 0a682fbc6192e1b47a5e0868787ffdafe5a50cead3575849990cdd2ea9b3597749403efb4a56684f0c6bde352d4aeec5
    // CT:  8886e196010cb3849d9c1a182abe1eeab0a5f3ca423c3669a4a8703c0f146e8e956fb122e0d721b869d2b6fcd4216d7d4d3758
    // Tag: 2469cecd70fd98fec9264f71df1aee9a

    private func vector2Key() -> SymmetricKey {
        SymmetricKey(data: hexToData("463b412911767d57a0b33969e674ffe7845d313b88c6fe312f3d724be68e1fca"))
    }

    private func vector2Nonce() throws -> AES.GCM.Nonce {
        try AES.GCM.Nonce(data: hexToData("611ce6f9a6880750de7da6cb"))
    }

    private func vector2PT() -> Data {
        hexToData("e7d1dcf668e2876861940e012fe52a98dacbd78ab63c08842cc9801ea581682ad54af0c34d0d7f6f59e8ee0bf4900e0fd85042")
    }

    private func vector2AAD() -> Data {
        hexToData("0a682fbc6192e1b47a5e0868787ffdafe5a50cead3575849990cdd2ea9b3597749403efb4a56684f0c6bde352d4aeec5")
    }

    // MARK: - NIST CAVP Vector 3 (All-zeros key, nonce, 16-byte zero plaintext)
    // Key: 0000000000000000000000000000000000000000000000000000000000000000
    // IV:  000000000000000000000000
    // PT:  00000000000000000000000000000000
    // AAD: (empty)
    // CT:  cea7403d4d606b6e074ec5d3baf39d18
    // Tag: d0d1c8a799996bf0265b98b5d48ab919

    private func vector3Key() -> SymmetricKey {
        SymmetricKey(data: hexToData("0000000000000000000000000000000000000000000000000000000000000000"))
    }

    private func vector3Nonce() throws -> AES.GCM.Nonce {
        try AES.GCM.Nonce(data: hexToData("000000000000000000000000"))
    }

    // MARK: - Test 1: Encrypt Known Answer — Empty Plaintext (Vector 1)

    func testEncryptKnownAnswer_EmptyPlaintext() throws {
        let key = vector1Key()
        let nonce = try vector1Nonce()

        let sealedBox = try AES.GCM.seal(Data(), using: key, nonce: nonce)

        XCTAssertEqual(Data(sealedBox.ciphertext).count, 0, "Ciphertext should be empty for empty plaintext")
        XCTAssertEqual(Data(sealedBox.tag), hexToData("bdc1ac884d332457a1d2664f168c76f0"), "Tag must match NIST known answer")
    }

    // MARK: - Test 2: Encrypt Known Answer — With AAD (Vector 2)

    func testEncryptKnownAnswer_WithAAD() throws {
        let key = vector2Key()
        let nonce = try vector2Nonce()
        let pt = vector2PT()
        let aad = vector2AAD()

        let sealedBox = try AES.GCM.seal(pt, using: key, nonce: nonce, authenticating: aad)

        XCTAssertEqual(Data(sealedBox.ciphertext), hexToData("8886e196010cb3849d9c1a182abe1eeab0a5f3ca423c3669a4a8703c0f146e8e956fb122e0d721b869d2b6fcd4216d7d4d3758"))
        XCTAssertEqual(Data(sealedBox.tag), hexToData("2469cecd70fd98fec9264f71df1aee9a"))
    }

    // MARK: - Test 3: Encrypt Known Answer — Zero Key (Vector 3)

    func testEncryptKnownAnswer_ZeroKey() throws {
        let key = vector3Key()
        let nonce = try vector3Nonce()
        let pt = hexToData("00000000000000000000000000000000")

        let sealedBox = try AES.GCM.seal(pt, using: key, nonce: nonce)

        XCTAssertEqual(Data(sealedBox.ciphertext), hexToData("cea7403d4d606b6e074ec5d3baf39d18"))
        XCTAssertEqual(Data(sealedBox.tag), hexToData("d0d1c8a799996bf0265b98b5d48ab919"))
    }

    // MARK: - Test 4: Decrypt Known Answer — With AAD (Vector 2)

    func testDecryptKnownAnswer_WithAAD() throws {
        let key = vector2Key()
        let nonce = try vector2Nonce()
        let ct = hexToData("8886e196010cb3849d9c1a182abe1eeab0a5f3ca423c3669a4a8703c0f146e8e956fb122e0d721b869d2b6fcd4216d7d4d3758")
        let tag = hexToData("2469cecd70fd98fec9264f71df1aee9a")
        let aad = vector2AAD()
        let expectedPT = vector2PT()

        let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ct, tag: tag)
        let decrypted = try AES.GCM.open(sealedBox, using: key, authenticating: aad)

        XCTAssertEqual(decrypted, expectedPT, "Decrypted plaintext must match NIST known answer")
    }

    // MARK: - Test 5: Decrypt Tampered Tag Fails

    func testDecryptTamperedTag_Fails() throws {
        let key = SymmetricKey(size: .bits256)
        let pt = Data("secret message".utf8)
        var package = try service.encrypt(plaintext: pt, using: key)

        package.tag = Data((0..<16).map { _ in UInt8.random(in: 0...255) })

        XCTAssertThrowsError(try service.decrypt(package: package, using: key))
    }

    // MARK: - Test 6: Decrypt Tampered Ciphertext Fails

    func testDecryptTamperedCiphertext_Fails() throws {
        let key = SymmetricKey(size: .bits256)
        let pt = Data("secret message".utf8)
        var package = try service.encrypt(plaintext: pt, using: key)

        guard !package.ciphertext.isEmpty else {
            XCTFail("Ciphertext should not be empty for non-empty plaintext")
            return
        }

        package.ciphertext = Data((0..<package.ciphertext.count).map { _ in UInt8.random(in: 0...255) })

        XCTAssertThrowsError(try service.decrypt(package: package, using: key))
    }

    // MARK: - Test 7: Decrypt Wrong Nonce Fails

    func testDecryptWrongNonce_Fails() throws {
        let key = SymmetricKey(size: .bits256)
        let pt = Data("secret message".utf8)
        var package = try service.encrypt(plaintext: pt, using: key)

        // Generate a different nonce
        let wrongNonce = AES.GCM.Nonce()
        package.nonce = wrongNonce.withUnsafeBytes { Data($0) }

        XCTAssertThrowsError(try service.decrypt(package: package, using: key)) { error in
            XCTAssertEqual(error as? CryptoKitError, .authenticationFailure)
        }
    }

    // MARK: - Test 8: Decrypt Wrong Key Fails

    func testDecryptWrongKey_Fails() throws {
        let key = SymmetricKey(size: .bits256)
        let pt = Data("secret message".utf8)
        let package = try service.encrypt(plaintext: pt, using: key)

        // Use a different key
        let wrongKey = SymmetricKey(size: .bits256)

        XCTAssertThrowsError(try service.decrypt(package: package, using: wrongKey)) { error in
            XCTAssertEqual(error as? CryptoKitError, .authenticationFailure)
        }
    }

    // MARK: - Test 9: Round-Trip Various Sizes

    func testRoundTrip_VariousSizes() throws {
        let key = SymmetricKey(size: .bits256)

        let sizes: [Int] = [0, 1, 16, 1024, 100 * 1024]
        for size in sizes {
            let original = Data((0..<size).map { UInt8($0 & 0xFF) })
            let package = try service.encrypt(plaintext: original, using: key)
            let decrypted = try service.decrypt(package: package, using: key)
            XCTAssertEqual(decrypted, original, "Round-trip failed for size \(size)")
        }
    }

    // MARK: - Test 10: Combined Format Round-Trip

    func testCombinedFormat_RoundTrip() throws {
        let key = SymmetricKey(size: .bits256)
        let original = Data("test combined format".utf8)

        let package = try service.encrypt(plaintext: original, using: key)
        let combined = package.combined

        // Reconstruct from combined format
        let reconstructed = try EncryptedPackage(combined: combined)
        let decrypted = try service.decrypt(package: reconstructed, using: key)

        XCTAssertEqual(decrypted, original)
    }

    // MARK: - Test 11: Encrypt with Random Nonce Produces Different Ciphertexts

    func testEncryptWithRandomNonce() throws {
        let key = SymmetricKey(size: .bits256)
        let pt = Data("same plaintext".utf8)

        let package1 = try service.encrypt(plaintext: pt, using: key)
        let package2 = try service.encrypt(plaintext: pt, using: key)

        // Nonces must be different
        XCTAssertNotEqual(package1.nonce, package2.nonce, "Random nonces should differ")
        // Consequently, ciphertexts must differ
        XCTAssertNotEqual(package1.ciphertext, package2.ciphertext, "Ciphertexts should differ with different nonces")
        // Tags must also differ (different nonce → different CTR output → different GHASH input)
        XCTAssertNotEqual(package1.tag, package2.tag, "Tags should differ with different nonces")
    }

    // MARK: - Test 12: Decrypt Invalid Combined Size Fails

    func testDecryptInvalidCombinedSize_Fails() throws {
        // 27 bytes is one short of the minimum 28
        let tooSmall = Data(repeating: 0, count: 27)

        XCTAssertThrowsError(try EncryptedPackage(combined: tooSmall)) { error in
            XCTAssertEqual(error as? EncryptionError, .invalidCombinedData)
        }
    }
}
