//
//  HistoryPanelViewTests.swift
//  ClipVaultTests
//

import XCTest
import SwiftUI
@testable import ClipVault

@MainActor
final class HistoryPanelViewTests: XCTestCase {
    
    func testHistoryPanelView_ActionsAreCalled() {
        let viewModel = ClipboardViewModel(repository: ClipboardRepository(), pasteService: PasteService())
        
        var closeCalled = false
        var settingsCalled = false
        var quitCalled = false
        
        let view = HistoryPanelView(
            viewModel: viewModel,
            onClose: { closeCalled = true },
            onOpenSettings: { settingsCalled = true },
            onQuit: { quitCalled = true }
        )
        
        // Directly trigger closures
        view.onClose?()
        view.onOpenSettings?()
        view.onQuit?()
        
        XCTAssertTrue(closeCalled)
        XCTAssertTrue(settingsCalled)
        XCTAssertTrue(quitCalled)
    }
}
