//
//  PrivacyIgnoreList.swift
//  ClipVault
//
//  Utility namespace for privacy ignore-list defaults and matching logic.
//

import Foundation

/// Utility type for the Privacy Ignore List feature.
/// Holds default blocked bundle IDs and provides matching helpers.
enum PrivacyIgnoreList {

    /// Default bundle IDs for known password managers / credential stores.
    static let defaultIgnoredBundleIDs: [String] = [
        "com.agilebits.onepassword-osx",   // 1Password 7
        "com.agilebits.onepassword7",       // 1Password 7 (alternate)
        "com.1password.1password",          // 1Password 8
        "com.apple.keychainaccess",         // Keychain Access
        "com.bitwarden.desktop",            // Bitwarden
    ]

    /// Returns `true` when `bundleID` is in the given `ignoredList` (case-insensitive).
    static func isIgnored(bundleID: String?, in ignoredList: [String]) -> Bool {
        guard let bundleID = bundleID else { return false }
        return ignoredList.contains { $0.lowercased() == bundleID.lowercased() }
    }
}
