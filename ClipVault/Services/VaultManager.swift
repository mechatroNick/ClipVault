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
    
    private init() {
        try? ensureVaultExists()
    }
    
    /// Saves data to the vault, organized by year and month, encrypted using AES-GCM.
    /// - Returns: The relative path within the vault (e.g., "2024-05/UUID.png").
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
        
        return "\(folderName)/\(fileName)"
    }
    
    /// Loads and decrypts data from the vault.
    ///
    /// - Parameters:
    ///   - path: The relative path or absolute path to the encrypted file.
    ///   - key: The symmetric key for decryption.
    /// - Returns: The decrypted data.
    func loadFromVault(at path: String, using key: SymmetricKey) throws -> Data {
        let fileURL: URL
        if path.hasPrefix("/") {
            fileURL = URL(fileURLWithPath: path)
        } else {
            let root = URL(fileURLWithPath: settings.vaultRootPath)
            fileURL = root.appendingPathComponent(path)
        }
        
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

    /// Calculates the total size of the vault in bytes.
    func calculateVaultSize() -> Int64 {
        let root = URL(fileURLWithPath: settings.vaultRootPath)
        var totalSize: Int64 = 0
        let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.fileSizeKey])
        
        while let fileURL = enumerator?.nextObject() as? URL {
            if let resources = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
               let fileSize = resources.fileSize {
                totalSize += Int64(fileSize)
            }
        }
        return totalSize
    }

    /// Trims the vault to stay within the storage limit.
    /// Deletes the oldest files first.
    func trimVault() throws {
        guard settings.isAutoTrimEnabled else { return }
        let limitBytes = Int64(settings.vaultStorageLimitGB) * 1024 * 1024 * 1024
        var currentSize = calculateVaultSize()
        
        if currentSize <= limitBytes { return }
        
        let root = URL(fileURLWithPath: settings.vaultRootPath)
        let keys: [URLResourceKey] = [.fileSizeKey, .contentModificationDateKey]
        let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: keys)
        
        var files: [(url: URL, size: Int64, date: Date)] = []
        while let fileURL = enumerator?.nextObject() as? URL {
            let resources = try? fileURL.resourceValues(forKeys: Set(keys))
            if let fileSize = resources?.fileSize,
               let modDate = resources?.contentModificationDate {
                files.append((url: fileURL, size: Int64(fileSize), date: modDate))
            }
        }
        
        // Sort by modification date (oldest first)
        files.sort { $0.date < $1.date }
        
        for file in files {
            if currentSize <= limitBytes { break }
            try FileManager.default.removeItem(at: file.url)
            currentSize -= file.size
            print("VaultManager: Purged old file: \(file.url.lastPathComponent)")
        }
    }
}
