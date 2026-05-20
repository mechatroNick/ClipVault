//
//  HistoryPanel.swift
//  ClipVault
//

import AppKit
import SwiftUI

final class HistoryPanel: NSPanel {
    init(contentView: NSView) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 500),
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView, .resizable],
            backing: .buffered,
            defer: false
        )
        
        self.isFloatingPanel = true
        self.level = .statusBar
        self.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle, .stationary]
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.isMovableByWindowBackground = true
        self.hasShadow = true
        self.backgroundColor = .clear
        self.isOpaque = false
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true
        
        self.contentView = contentView
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
}
