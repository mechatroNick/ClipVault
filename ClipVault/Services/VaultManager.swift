//
//  VaultManager.swift
//  ClipVault
//

import Foundation
import CryptoKit

/// Manages the organization and persistence of large clipboard content in a structured file hierarchy.
final class VaultManager {
    static let shared = VaultManager()
    
    private let settings = SettingsManager.shared
    private let encryptionService = EncryptionService()
    
    private init() {}
    
    /// Saves data to the vault, organized by year and month, encrypted using AES-GCM.
    ///
    /// - Parameters:
    ///   - data: The data to save.
    ///   - ext: The file extension (e.g., "png", "txt").
    ///   - key: The symmetric key for encryption.
    /// - Returns: The full path to the saved file.
    func saveToVault(data: Data, extension ext: String, using key: SymmetricKey) throws -> String {
        let root = URL(fileURLWithPath: settings.vaultRootPath)
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let folderName = formatter.string(from: date)
        
        let targetFolder = root.appendingPathComponent(folderName)
        
        if !FileManager.default.fileExists(atPath: targetFolder.path) {
            try FileManager.default.createDirectory(at: targetFolder, withIntermediateDirectories: true)
        }
        
        let fileName = "\(UUID().uuidString).\(ext)"
        let fileURL = targetFolder.appendingPathComponent(fileName)
        
        let encrypted = try encryptionService.encrypt(plaintext: data, using: key)
        try encrypted.combined.write(to: fileURL)
        
        return fileURL.path
    }
    
    /// Loads and decrypts data from the vault.
    ///
    /// - Parameters:
    ///   - path: The full path to the encrypted file.
    ///   - key: The symmetric key for decryption.
    /// - Returns: The decrypted data.
    func loadFromVault(at path: String, using key: SymmetricKey) throws -> Data {
        let fileURL = URL(fileURLWithPath: path)
        let encryptedData = try Data(contentsOf: fileURL)
        let package = try EncryptedPackage(combined: encryptedData)
        return try encryptionService.decrypt(package: package, using: key)
    }
    
    /// Ensures the vault root exists.
    func ensureVaultExists() throws {
        let root = URL(fileURLWithPath: settings.vaultRootPath)
        if !FileManager.default.fileExists(atPath: root.path) {
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        }
    }
}
