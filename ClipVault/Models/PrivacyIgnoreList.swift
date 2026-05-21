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

    /// Returns `true` when `bundleID` is in the given `ignoredSet` (case-insensitive O(1) lookup).
    static func isIgnored(bundleID: String?, in ignoredSet: Set<String>) -> Bool {
        guard let bundleID else { return false }
        return ignoredSet.contains(bundleID.lowercased())
    }

    /// Converts a bundle-ID array into a lowercased `Set` for efficient repeated lookups.
    static func makeIgnoredSet(from list: [String]) -> Set<String> {
        Set(list.map { $0.lowercased() })
    }
}
