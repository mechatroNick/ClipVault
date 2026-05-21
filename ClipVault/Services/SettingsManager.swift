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

    @Published var panelWidth: CGFloat {
        didSet { UserDefaults.standard.set(Double(panelWidth), forKey: Keys.panelWidth) }
    }

    @Published var panelHeight: CGFloat {
        didSet { UserDefaults.standard.set(Double(panelHeight), forKey: Keys.panelHeight) }
    }

    @Published var zoomLevel: Double {
        didSet { UserDefaults.standard.set(zoomLevel, forKey: Keys.zoomLevel) }
    }

    @Published var sensitivePurgeTimeHours: Int {
        didSet { UserDefaults.standard.set(sensitivePurgeTimeHours, forKey: Keys.sensitivePurgeTimeHours) }
    }

    @Published var vaultStorageLimitGB: Int {
        didSet { UserDefaults.standard.set(vaultStorageLimitGB, forKey: Keys.vaultStorageLimitGB) }
    }

    @Published var isAutoTrimEnabled: Bool {
        didSet { UserDefaults.standard.set(isAutoTrimEnabled, forKey: Keys.isAutoTrimEnabled) }
    }
    
    @Published var simulatePasteEnabled: Bool {
        didSet { UserDefaults.standard.set(simulatePasteEnabled, forKey: Keys.simulatePasteEnabled) }
    }

    @Published var globalHotkey: HotkeyDescriptor {
        didSet {
            if let data = try? JSONEncoder().encode(globalHotkey) {
                UserDefaults.standard.set(data, forKey: Keys.globalHotkey)
            }
        }
    }

    @Published var ignoredBundleIDs: [String] {
        didSet { UserDefaults.standard.set(ignoredBundleIDs, forKey: Keys.ignoredBundleIDs) }
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
                UserDefaults.standard.set(intended, forKey: Keys.launchAtLogin)
            } catch {
                print("LaunchAtLogin: Failed to \(intended ? "register" : "unregister"): \(error)")
                let actual = SMAppService.mainApp.status == .enabled
                if actual != launchAtLogin {
                    launchAtLogin = actual
                }
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
        static let panelWidth = "cv_panelWidth"
        static let panelHeight = "cv_panelHeight"
        static let zoomLevel = "cv_zoomLevel"
        static let sensitivePurgeTimeHours = "cv_sensitivePurgeTimeHours"
        static let vaultStorageLimitGB = "cv_vaultStorageLimitGB"
        static let isAutoTrimEnabled = "cv_isAutoTrimEnabled"
        static let launchAtLogin = "cv_launchAtLogin"
        static let simulatePasteEnabled = "cv_simulatePasteEnabled"
        static let globalHotkey = "cv_globalHotkey"
        static let ignoredBundleIDs = "cv_ignoredBundleIDs"
    }
    
    private init() {
        self.retentionDays = UserDefaults.standard.integer(forKey: Keys.retentionDays) == 0 ? 7 : UserDefaults.standard.integer(forKey: Keys.retentionDays)
        self.largeFileThresholdMB = UserDefaults.standard.integer(forKey: Keys.largeFileThresholdMB) == 0 ? 5 : UserDefaults.standard.integer(forKey: Keys.largeFileThresholdMB)
        self.maxEntries = UserDefaults.standard.integer(forKey: Keys.maxEntries) == 0 ? 50 : UserDefaults.standard.integer(forKey: Keys.maxEntries)
        self.simulatePasteEnabled = UserDefaults.standard.bool(forKey: Keys.simulatePasteEnabled)

        // Global hotkey
        if let data = UserDefaults.standard.data(forKey: Keys.globalHotkey),
           let hotkey = try? JSONDecoder().decode(HotkeyDescriptor.self, from: data) {
            self.globalHotkey = hotkey
        } else {
            self.globalHotkey = .default
        }

        // Privacy ignore list
        self.ignoredBundleIDs = UserDefaults.standard.stringArray(forKey: Keys.ignoredBundleIDs) ?? PrivacyIgnoreList.defaultIgnoredBundleIDs
        
        if let path = UserDefaults.standard.string(forKey: Keys.vaultRootPath) {
            self.vaultRootPath = path
        } else {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            self.vaultRootPath = docs.appendingPathComponent("VaultClip").path
        }
        
        self.customPatterns = UserDefaults.standard.dictionary(forKey: Keys.customPatterns) as? [String: String] ?? [:]
        
        self.panelWidth = UserDefaults.standard.double(forKey: Keys.panelWidth) == 0 ? 420 : CGFloat(UserDefaults.standard.double(forKey: Keys.panelWidth))
        self.panelHeight = UserDefaults.standard.double(forKey: Keys.panelHeight) == 0 ? 500 : CGFloat(UserDefaults.standard.double(forKey: Keys.panelHeight))
        self.zoomLevel = UserDefaults.standard.double(forKey: Keys.zoomLevel) == 0 ? 1.0 : UserDefaults.standard.double(forKey: Keys.zoomLevel)

        self.sensitivePurgeTimeHours = UserDefaults.standard.integer(forKey: Keys.sensitivePurgeTimeHours) == 0 ? 1 : UserDefaults.standard.integer(forKey: Keys.sensitivePurgeTimeHours)
        self.vaultStorageLimitGB = UserDefaults.standard.integer(forKey: Keys.vaultStorageLimitGB) == 0 ? 10 : UserDefaults.standard.integer(forKey: Keys.vaultStorageLimitGB)
        self.isAutoTrimEnabled = UserDefaults.standard.object(forKey: Keys.isAutoTrimEnabled) == nil ? true : UserDefaults.standard.bool(forKey: Keys.isAutoTrimEnabled)

        let currentStatus = (SMAppService.mainApp.status == .enabled)
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
