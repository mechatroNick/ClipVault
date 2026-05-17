//
//  PasteboardMonitor.swift
//  ClipVault
//
//  Created by ClipVault.
//

import AppKit

/// Protocol to abstract NSPasteboard for unit testing.
protocol PasteboardType {
    var changeCount: Int { get }
    var types: [NSPasteboard.PasteboardType]? { get }
    func string(forType dataType: NSPasteboard.PasteboardType) -> String?
    func data(forType dataType: NSPasteboard.PasteboardType) -> Data?
}

extension NSPasteboard: PasteboardType {}

/// Monitors the system pasteboard for changes via polling and emits
/// updates via an AsyncStream. Includes app lifecycle awareness to pause
/// when the app is inactive if needed, and filtering for self-copies.
final class PasteboardMonitor: @unchecked Sendable {
    private let pasteboard: PasteboardType
    private let pollInterval: TimeInterval
    
    private var timer: Timer?
    private var lastChangeCount: Int
    
    private var continuation: AsyncStream<Int>.Continuation?
    
    /// If true, the next detected change is ignored (used when the app itself pastes/copies).
    private var ignoreNextChange = false
    
    init(pasteboard: PasteboardType = NSPasteboard.general, pollInterval: TimeInterval = 0.5) {
        self.pasteboard = pasteboard
        self.pollInterval = pollInterval
        self.lastChangeCount = pasteboard.changeCount
    }
    
    /// Starts monitoring and returns a stream of new change counts.
    func start() -> AsyncStream<Int> {
        let (stream, cont) = AsyncStream<Int>.makeStream()
        self.continuation = cont
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.lastChangeCount = self.pasteboard.changeCount
            let t = Timer(timeInterval: self.pollInterval, repeats: true) { [weak self] _ in
                self?.checkPasteboard()
            }
            RunLoop.main.add(t, forMode: .common)
            self.timer = t
        }
        
        return stream
    }
    
    /// Stops monitoring.
    func stop() {
        DispatchQueue.main.async { [weak self] in
            self?.timer?.invalidate()
            self?.timer = nil
            self?.continuation?.finish()
            self?.continuation = nil
        }
    }
    
    /// Tells the monitor to ignore the immediate next change count increment.
    func ignoreNextCopy() {
        DispatchQueue.main.async { [weak self] in
            self?.ignoreNextChange = true
        }
    }
    
    private func checkPasteboard() {
        let currentCount = pasteboard.changeCount
        if currentCount != lastChangeCount {
            lastChangeCount = currentCount
            if ignoreNextChange {
                ignoreNextChange = false
            } else {
                continuation?.yield(currentCount)
            }
        }
    }
}
