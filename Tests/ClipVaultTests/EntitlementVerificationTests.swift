import XCTest

final class EntitlementVerificationTests: XCTestCase {

    private var entitlements: [String: Any] = [:]

    override func setUpWithError() throws {
        try super.setUpWithError()

        let currentFileURL = URL(fileURLWithPath: #file)
        let projectRootURL = currentFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let entitlementsURL = projectRootURL
            .appendingPathComponent("ClipVault")
            .appendingPathComponent("ClipVault.entitlements")

        let data = try Data(contentsOf: entitlementsURL)
        let plist = try PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: nil
        )
        guard let dictionary = plist as? [String: Any] else {
            XCTFail("Entitlements plist is not a dictionary")
            return
        }
        self.entitlements = dictionary
    }

    override func tearDownWithError() throws {
        entitlements = [:]
        try super.tearDownWithError()
    }

    // MARK: - App Sandbox

    func testAppSandboxIsEnabled() {
        guard let sandboxEnabled = entitlements["com.apple.security.app-sandbox"] as? Bool else {
            XCTFail("com.apple.security.app-sandbox key is missing or not a boolean")
            return
        }
        XCTAssertTrue(sandboxEnabled, "App Sandbox must be enabled")
    }

    // MARK: - Network Client

    func testNetworkClientExplicitlyDisabled() {
        guard let networkClient = entitlements["com.apple.security.network.client"] as? Bool else {
            XCTFail("com.apple.security.network.client key is missing or not a boolean")
            return
        }
        XCTAssertFalse(networkClient, "com.apple.security.network.client must be explicitly false")
    }

    // MARK: - Network Server

    func testNetworkServerExplicitlyDisabled() {
        guard let networkServer = entitlements["com.apple.security.network.server"] as? Bool else {
            XCTFail("com.apple.security.network.server key is missing or not a boolean")
            return
        }
        XCTAssertFalse(networkServer, "com.apple.security.network.server must be explicitly false")
    }

    // MARK: - No Other Network Entitlements

    func testNoNetworkRelatedEntitlements() {
        let networkKeys = [
            "com.apple.security.network.client",
            "com.apple.security.network.server",
            "com.apple.developer.networking.wifi-info",
            "com.apple.developer.networking.networkextension",
            "com.apple.developer.dns-proxy",
        ]
        for key in networkKeys {
            if let value = entitlements[key] as? Bool {
                XCTAssertFalse(value, "\(key) must be false or absent, but was true")
            }
        }
    }

    // MARK: - Exact Key Set

    func testEntitlementsContainsExactlyExpectedKeys() {
        let expectedKeys: Set<String> = [
            "com.apple.security.app-sandbox",
            "com.apple.security.files.user-selected.read-only",
            "com.apple.security.network.client",
            "com.apple.security.network.server",
        ]
        let actualKeys = Set(entitlements.keys)
        XCTAssertEqual(
            actualKeys,
            expectedKeys,
            "Entitlements dictionary must contain exactly the expected keys. Unexpected: \(actualKeys.subtracting(expectedKeys)). Missing: \(expectedKeys.subtracting(actualKeys))."
        )
    }

    // MARK: - User Selected Read-Only

    func testUserSelectedReadOnlyEnabled() {
        guard let readOnlyEnabled = entitlements["com.apple.security.files.user-selected.read-only"] as? Bool else {
            XCTFail("com.apple.security.files.user-selected.read-only key is missing or not a boolean")
            return
        }
        XCTAssertTrue(readOnlyEnabled, "User-selected file read-only must be enabled")
    }
}
