//
//  SettingsManager.swift
//  ClipVault
//

import Foundation
import Combine
import ServiceManagement

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
    
    @Published var customPatterns: [String: String] {
        didSet { UserDefaults.standard.set(customPatterns, forKey: Keys.customPatterns) }
    }
    
    @Published var launchAtLogin: Bool = false {
        didSet {
            let intended = launchAtLogin
            do {
                if intended {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                // Only persist to UserDefaults after confirmed success
                UserDefaults.standard.set(intended, forKey: Keys.launchAtLogin)
            } catch {
                print("LaunchAtLogin: Failed to \(intended ? "register" : "unregister"): \(error)")
                // Revert property to actual system state and sync UserDefaults
                let actual = SMAppService.mainApp.status == .enabled
                launchAtLogin = actual
                UserDefaults.standard.set(actual, forKey: Keys.launchAtLogin)
            }
        }
    }
    
    private enum Keys {
        static let retentionDays = "cv_retentionDays"
        static let largeFileThresholdMB = "cv_largeFileThresholdMB"
        static let maxEntries = "cv_maxEntries"
        static let vaultRootPath = "cv_vaultRootPath"
        static let customPatterns = "cv_customPatterns"
        static let launchAtLogin = "cv_launchAtLogin"
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
        
        self.customPatterns = UserDefaults.standard.dictionary(forKey: Keys.customPatterns) as? [String: String] ?? [:]
        
        // Prefer actual SMAppService status over UserDefaults for launchAtLogin,
        // since the user can change it in System Settings independently.
        // .notFound and .requiresApproval both map to false (not enabled).
        let currentStatus = (SMAppService.mainApp.status == .enabled)
        
        // Default to enabled on first launch
        if UserDefaults.standard.object(forKey: Keys.launchAtLogin) == nil {
            if !currentStatus {
                do {
                    try SMAppService.mainApp.register()
                    launchAtLogin = true
                    UserDefaults.standard.set(true, forKey: Keys.launchAtLogin)
                } catch {
                    print("LaunchAtLogin: Initial registration failed: \(error)")
                    launchAtLogin = false
                }
            } else {
                launchAtLogin = true
                UserDefaults.standard.set(true, forKey: Keys.launchAtLogin)
            }
        } else {
            launchAtLogin = currentStatus
        }
    }
}
