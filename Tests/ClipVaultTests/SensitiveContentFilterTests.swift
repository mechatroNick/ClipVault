//
//  SensitiveContentFilterTests.swift
//  ClipVaultTests
//
//  Created by ClipVault.
//

import XCTest
@testable import ClipVault

final class SensitiveContentFilterTests: XCTestCase {
    
    private let filter = SensitiveContentFilter()
    
    func testRedact_CreditCard() {
        let input = "My card is 4111 1111 1111 1111."
        let result = filter.redact(input)
        XCTAssertEqual(result, "My card is [REDACTED Credit Card].")
    }
    
    func testRedact_SSN() {
        let input = "SSN is 123-45-6789."
        let result = filter.redact(input)
        XCTAssertEqual(result, "SSN is [REDACTED SSN].")
    }
    
    func testRedact_IPv4() {
        let input = "IP: 192.168.1.1"
        let result = filter.redact(input)
        XCTAssertEqual(result, "IP: [REDACTED IPv4]")
    }
    
    func testRedact_Secret() {
        let input = "export GITHUB_TOKEN=ghp_abcdefghijklmnopqrstuvwxyz0123456789"
        let result = filter.redact(input)
        XCTAssertTrue(result.contains("[REDACTED Secret]"))
        XCTAssertFalse(result.contains("ghp_abcdefgh"))
    }
    
    func testRedact_Password() {
        let input = "The password is super_secret_password_123"
        let result = filter.redact(input)
        XCTAssertTrue(result.contains("[REDACTED Secret]"))
        XCTAssertFalse(result.contains("super_secret"))
    }
    
    func testContainsSensitiveContent_ReturnsTrue() {
        XCTAssertTrue(filter.containsSensitiveContent("4111-1111-1111-1111"))
        XCTAssertTrue(filter.containsSensitiveContent("123-45-6789"))
        XCTAssertTrue(filter.containsSensitiveContent("password=mysecret"))
    }
    
    func testContainsSensitiveContent_ReturnsFalse() {
        XCTAssertFalse(filter.containsSensitiveContent("Hello World"))
        XCTAssertFalse(filter.containsSensitiveContent("123-456-789")) // Not a valid SSN format
    }
}
