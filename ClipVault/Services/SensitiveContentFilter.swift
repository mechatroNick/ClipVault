//
//  SensitiveContentFilter.swift
//  ClipVault
//
//  Created by ClipVault.
//

import Foundation

/// Detects and redacts sensitive information like credit cards and secrets.
final class SensitiveContentFilter {
    
    private let builtInPatterns: [String: String] = [
        "Credit Card": #"\b(?:\d[ -]*?){13,16}\b"#,
        "SSN": #"\b\d{3}-\d{2}-\d{4}\b"#,
        "IPv4": #"\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b"#,
        "Secret": #"(?i)(?:key|secret|token|password|auth|passwd|credential)[^a-z0-9]{1,10}[a-z0-9+/_.-]{8,}"#
    ]
    
    private var compiledRegexes: [String: NSRegularExpression] = [:]
    private var lastCustomPatterns: [String: String] = [:]
    
    init() {
        updateRegexCache()
    }
    
    private func updateRegexCache() {
        let custom = SettingsManager.shared.customPatterns
        if custom == lastCustomPatterns && !compiledRegexes.isEmpty { return }
        
        lastCustomPatterns = custom
        var newCache: [String: NSRegularExpression] = [:]
        
        let all = builtInPatterns.merging(custom) { (_, new) in new }
        
        for (label, pattern) in all {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                newCache[label] = regex
            }
        }
        compiledRegexes = newCache
    }
    
    /// Returns a version of the text where sensitive patterns are replaced with redaction labels.
    func redact(_ text: String) -> String {
        updateRegexCache()
        var redacted = text
        for (label, regex) in compiledRegexes {
            let range = NSRange(redacted.startIndex..., in: redacted)
            redacted = regex.stringByReplacingMatches(in: redacted, range: range, withTemplate: "[REDACTED \(label)]")
        }
        return redacted
    }
    
    /// Quickly checks if a string contains any sensitive content.
    func containsSensitiveContent(_ text: String) -> Bool {
        updateRegexCache()
        for regex in compiledRegexes.values {
            let range = NSRange(text.startIndex..., in: text)
            if regex.firstMatch(in: text, range: range) != nil {
                return true
            }
        }
        return false
    }
}
