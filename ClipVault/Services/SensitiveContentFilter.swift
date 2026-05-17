//
//  SensitiveContentFilter.swift
//  ClipVault
//
//  Created by ClipVault.
//

import Foundation

/// Detects and redacts sensitive information like credit cards and secrets.
struct SensitiveContentFilter {
    
    /// Regex patterns for common sensitive data types.
    private let patterns: [String: String] = [
        "Credit Card": #"\b(?:\d[ -]*?){13,16}\b"#,
        "SSN": #"\b\d{3}-\d{2}-\d{4}\b"#,
        "IPv4": #"\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b"#,
        // Generic secret/key pattern (case-insensitive labels followed by entropy-rich strings)
        "Secret": #"(?i)(?:key|secret|token|password|auth|passwd|credential)[^a-z0-9]{1,10}[a-z0-9+/_.-]{8,}"#
    ]
    
    /// Returns a version of the text where sensitive patterns are replaced with redaction labels.
    ///
    /// - Parameter text: The input string to filter.
    /// - Returns: Redacted string for safe storage in plaintext indexes.
    func redact(_ text: String) -> String {
        var redacted = text
        for (label, pattern) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(redacted.startIndex..., in: redacted)
                redacted = regex.stringByReplacingMatches(in: redacted, range: range, withTemplate: "[REDACTED \(label)]")
            }
        }
        return redacted
    }
    
    /// Quickly checks if a string contains any sensitive content.
    ///
    /// - Parameter text: The string to check.
    /// - Returns: True if any pattern matches.
    func containsSensitiveContent(_ text: String) -> Bool {
        for pattern in patterns.values {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(text.startIndex..., in: text)
                if regex.firstMatch(in: text, range: range) != nil {
                    return true
                }
            }
        }
        return false
    }
}
