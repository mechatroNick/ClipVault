//
//  VaultManager.swift
//  ClipVault
//

import Foundation

/// Manages the organization and persistence of large clipboard content in a structured file hierarchy.
final class VaultManager {
    static let shared = VaultManager()
    
    private let settings = SettingsManager.shared
    
    private init() {}
    
    /// Saves data to the vault, organized by year and month.
    ///
    /// - Parameters:
    ///   - data: The data to save.
    ///   - extension: The file extension (e.g., "png", "txt").
    /// - Returns: The full path to the saved file.
    func saveToVault(data: Data, extension ext: String) throws -> String {
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
        
        try data.write(to: fileURL)
        return fileURL.path
    }
    
    /// Ensures the vault root exists.
    func ensureVaultExists() throws {
        let root = URL(fileURLWithPath: settings.vaultRootPath)
        if !FileManager.default.fileExists(atPath: root.path) {
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        }
    }
}
