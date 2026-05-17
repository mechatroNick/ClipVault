//
//  SettingsManager.swift
//  ClipVault
//

import Foundation
import Combine

/// Manages application settings using UserDefaults.
final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var retentionDays: Int {
        didSet { UserDefaults.standard.set(retentionDays, forKey: Keys.retentionDays) }
    }
    
    @Published var largeFileThresholdMB: Int {
        didSet { UserDefaults.standard.set(largeFileThresholdMB, forKey: Keys.largeFileThresholdMB) }
    }
    
    @Published var maxEntries: Int {
        didSet { UserDefaults.standard.set(maxEntries, forKey: Keys.maxEntries) }
    }
    
    @Published var vaultRootPath: String {
        didSet { UserDefaults.standard.set(vaultRootPath, forKey: Keys.vaultRootPath) }
    }
    
    private enum Keys {
        static let retentionDays = "cv_retentionDays"
        static let largeFileThresholdMB = "cv_largeFileThresholdMB"
        static let maxEntries = "cv_maxEntries"
        static let vaultRootPath = "cv_vaultRootPath"
    }
    
    private init() {
        self.retentionDays = UserDefaults.standard.integer(forKey: Keys.retentionDays) == 0 ? 7 : UserDefaults.standard.integer(forKey: Keys.retentionDays)
        self.largeFileThresholdMB = UserDefaults.standard.integer(forKey: Keys.largeFileThresholdMB) == 0 ? 5 : UserDefaults.standard.integer(forKey: Keys.largeFileThresholdMB)
        self.maxEntries = UserDefaults.standard.integer(forKey: Keys.maxEntries) == 0 ? 50 : UserDefaults.standard.integer(forKey: Keys.maxEntries)
        
        if let path = UserDefaults.standard.string(forKey: Keys.vaultRootPath) {
            self.vaultRootPath = path
        } else {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            self.vaultRootPath = docs.appendingPathComponent("VaultClip").path
        }
    }
}
