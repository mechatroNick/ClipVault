//
//  PasteboardMonitorTests.swift
//  ClipVaultTests
//
//  Created by ClipVault.
//

import XCTest
@testable import ClipVault

final class MockPasteboard: PasteboardType {
    var changeCount: Int = 0
    var types: [NSPasteboard.PasteboardType]? = []
    
    private var strings: [NSPasteboard.PasteboardType: String] = [:]
    private var dataDict: [NSPasteboard.PasteboardType: Data] = [:]
    
    func string(forType dataType: NSPasteboard.PasteboardType) -> String? {
        return strings[dataType]
    }
    
    func data(forType dataType: NSPasteboard.PasteboardType) -> Data? {
        return dataDict[dataType]
    }
    
    // Test helpers
    func simulateCopy(string: String, type: NSPasteboard.PasteboardType = .string) {
        strings[type] = string
        if types?.contains(type) == false {
            types?.append(type)
        }
        changeCount += 1
    }
    
    func simulateCopy(data: Data, type: NSPasteboard.PasteboardType) {
        dataDict[type] = data
        if types?.contains(type) == false {
            types?.append(type)
        }
        changeCount += 1
    }
}

final class PasteboardMonitorTests: XCTestCase {
    
    func testChangeDetection_EmitsOnNewCount() async throws {
        // Arrange
        let mock = MockPasteboard()
        let monitor = PasteboardMonitor(pasteboard: mock, pollInterval: 0.1)
        let stream = monitor.start()
        
        // Act
        // Simulate a copy after a brief delay
        Task {
            try await Task.sleep(nanoseconds: 150_000_000) // 150ms
            mock.simulateCopy(string: "Test copy")
        }
        
        // Assert
        var iterator = stream.makeAsyncIterator()
        let firstChange = await iterator.next()
        
        XCTAssertEqual(firstChange, 1)
        
        monitor.stop()
    }
    
    func testIgnoreNextCopy_FiltersSelfCopy() async throws {
        // Arrange
        let mock = MockPasteboard()
        let monitor = PasteboardMonitor(pasteboard: mock, pollInterval: 0.1)
        let stream = monitor.start()
        
        // Act
        monitor.ignoreNextCopy()
        
        Task {
            try await Task.sleep(nanoseconds: 100_000_000)
            mock.simulateCopy(string: "Self copy") // Count = 1, should be ignored
            
            try await Task.sleep(nanoseconds: 150_000_000)
            mock.simulateCopy(string: "External copy") // Count = 2, should be emitted
        }
        
        // Assert
        var iterator = stream.makeAsyncIterator()
        let emittedChange = await iterator.next()
        
        XCTAssertEqual(emittedChange, 2, "The first change (count 1) should have been ignored")
        
        monitor.stop()
    }
    
    func testStop_TerminatesStream() async throws {
        // Arrange
        let mock = MockPasteboard()
        let monitor = PasteboardMonitor(pasteboard: mock, pollInterval: 0.1)
        let stream = monitor.start()
        
        // Act
        monitor.stop()
        
        // Assert
        var iterator = stream.makeAsyncIterator()
        let next = await iterator.next()
        XCTAssertNil(next, "Stream should finish when stop() is called")
    }
}
