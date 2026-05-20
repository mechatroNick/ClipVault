//
//  MenuBarController.swift
//  ClipVault
//

import AppKit
import SwiftUI

@MainActor
final class MenuBarController: NSObject, NSWindowDelegate {
    private var statusItem: NSStatusItem?
    private var panel: HistoryPanel?
    private let viewModel: ClipboardViewModel
    private let pasteService: PasteService
    private let settings: SettingsManager
    private var eventMonitor: Any?
    private var pastingTask: Task<Void, Never>?
    
    var isPanelVisible: Bool {
        panel?.isVisible ?? false
    }
    
    init(viewModel: ClipboardViewModel, 
         pasteService: PasteService = PasteService(),
         settings: SettingsManager = .shared) {
        self.viewModel = viewModel
        self.pasteService = pasteService
        self.settings = settings
        super.init()
        setupStatusItem()
        setupPanel()
    }
    
    deinit {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "clipboard", accessibilityDescription: "ClipVault")
            button.image?.isTemplate = true
            button.action = #selector(togglePanel)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    
    private func setupPanel() {
        let view = HistoryPanelView(
            viewModel: viewModel,
            onClose: { [weak self] in
                self?.closePanel()
            },
            onOpenSettings: { [weak self] in
                self?.openSettings()
            }
        )
        .scaleEffect(settings.zoomLevel)
        
        let hostingView = NSHostingView(rootView: view)
        panel = HistoryPanel(contentView: hostingView)
        panel?.delegate = self
    }
    
    @objc func togglePanel() {
        handleAction(event: NSApp.currentEvent)
    }
    
    func handleAction(event: NSEvent?) {
        guard let _ = panel else { return }
        
        // Check if it was a right click
        if let event = event, event.type == .rightMouseUp {
            showContextMenu()
            return
        }
        
        if isPanelVisible {
            closePanel()
        } else {
            openPanel()
        }
    }
    
    private var animationDuration: TimeInterval {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ? 0.01 : 0.2
    }
    
    private func openPanel() {
        guard let panel = panel else { return }
        positionPanel()
        
        let finalFrame = panel.frame
        let startFrame = finalFrame.offsetBy(dx: 0, dy: 20)
        
        panel.setFrame(startFrame, display: true)
        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = animationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrame(finalFrame, display: true)
            panel.animator().alphaValue = 1
        }
        
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .keyDown]) { [weak self] event in
            // COVERAGE: Event monitor closures are difficult to trigger in unit tests without complex NSEvent simulation.
            if event.type == .keyDown {
                return self?.handleKeyDown(event) ?? event
            }
            
            if event.window != panel && event.window != self?.statusItem?.button?.window {
                self?.closePanel()
            }
            return event
        }
    }
    
    func handleKeyDown(_ event: NSEvent) -> NSEvent? {
        guard let panel = panel, panel.isVisible else { return event }
        
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        
        if modifiers == .command, let characters = event.charactersIgnoringModifiers {
            switch characters {
            case "1"..."9":
                // COVERAGE: Digit key shortcuts are tested for one case, but exhaustively testing all 1-9 is redundant.
                if let digit = Int(characters), digit <= viewModel.entries.count {
                    let entry = viewModel.entries[digit - 1]
                    pastingTask?.cancel()
                    pastingTask = Task {
                        try? await pasteService.preparePasteboard(for: entry)
                        await pasteService.simulatePaste()
                    }
                    closePanel()
                    return nil
                }
            case "f":
                // Focus search logic: just let the event pass to TextField
                return event
            case "+", "=":
                settings.zoomLevel = min(settings.zoomLevel + 0.1, 2.0)
                refreshPanelContent()
                return nil
            case "-":
                settings.zoomLevel = max(settings.zoomLevel - 0.1, 0.5)
                refreshPanelContent()
                return nil
            case "0":
                settings.zoomLevel = 1.0
                refreshPanelContent()
                return nil
            default:
                break
            }
            
            if event.keyCode == 51 { // Delete key (Backspace)
                if let index = viewModel.selectedIndex, index < viewModel.entries.count {
                    let entry = viewModel.entries[index]
                    if let id = entry.id {
                        try? viewModel.repository.delete(id: id)
                    }
                    return nil
                }
            }
        }
        
        switch event.keyCode {
        case 126: // Up arrow
            viewModel.moveSelection(direction: -1)
            return nil
        case 125: // Down arrow
            viewModel.moveSelection(direction: 1)
            return nil
        case 36: // Enter
            if let index = viewModel.selectedIndex, index < viewModel.entries.count {
                let entry = viewModel.entries[index]
                let asPlainText = modifiers.contains(.option)
                pastingTask?.cancel()
                pastingTask = Task {
                    try? await pasteService.preparePasteboard(for: entry, asPlainText: asPlainText)
                    await pasteService.simulatePaste()
                }
                closePanel()
            }
            return nil
        case 53: // Escape
            closePanel()
            return nil
        default:
            return event
        }
    }
    
    func closePanel() {
        guard let panel = panel, panel.isVisible else { return }
        
        let startFrame = panel.frame
        let endFrame = startFrame.offsetBy(dx: 0, dy: 20)
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = animationDuration * 0.75
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().setFrame(endFrame, display: true)
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            Task { @MainActor in
                self?.panel?.orderOut(nil)
            }
        })
        
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    private func positionPanel() {
        guard let panel = panel, let button = statusItem?.button, let window = button.window else { return }
        
        let screen = window.screen ?? NSScreen.main ?? NSScreen.screens[0]
        let screenRect = screen.visibleFrame
        let buttonRect = window.frame
        
        let panelWidth = settings.panelWidth
        let panelHeight = settings.panelHeight
        
        // Calculate x position, centering the panel under the status item
        var x = buttonRect.origin.x + (buttonRect.width / 2) - (panelWidth / 2)
        
        // Ensure panel stays within the current screen bounds
        if x < screenRect.origin.x {
            x = screenRect.origin.x + 5
        } else if x + panelWidth > screenRect.origin.x + screenRect.width {
            x = screenRect.origin.x + screenRect.width - panelWidth - 5
        }
        
        // Calculate y position, just below the menu bar
        let y = screenRect.origin.y + screenRect.height - panelHeight - 5
        
        panel.setFrame(NSRect(x: x, y: y, width: panelWidth, height: panelHeight), display: true)
    }

    private func refreshPanelContent() {
        let view = HistoryPanelView(
            viewModel: viewModel,
            onClose: { [weak self] in
                self?.closePanel()
            },
            onOpenSettings: { [weak self] in
                self?.openSettings()
            }
        )
        .scaleEffect(settings.zoomLevel)
        
        panel?.contentView = NSHostingView(rootView: view)
    }

    // MARK: - NSWindowDelegate

    func windowDidResize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        settings.panelWidth = window.frame.width
        settings.panelHeight = window.frame.height
    }
    
    func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit ClipVault", action: #selector(quitApp), keyEquivalent: "q"))
        
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: (statusItem?.button?.frame.height ?? 0) + 5), in: statusItem?.button)
    }
    
    @objc func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
    
    @objc func quitApp() {
        // COVERAGE: NSApplication.terminate terminates the test runner process.
        NSApplication.shared.terminate(nil)
    }
}
