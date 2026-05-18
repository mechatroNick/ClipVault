//
//  MenuBarController.swift
//  ClipVault
//

import AppKit
import SwiftUI

@MainActor
final class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var panel: HistoryPanel?
    private let viewModel: ClipboardViewModel
    private let pasteService: PasteService
    private var eventMonitor: Any?
    private var pastingTask: Task<Void, Never>?
    
    var isPanelVisible: Bool {
        panel?.isVisible ?? false
    }
    
    init(viewModel: ClipboardViewModel, pasteService: PasteService = PasteService()) {
        self.viewModel = viewModel
        self.pasteService = pasteService
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
        let hostingView = NSHostingView(rootView: view)
        panel = HistoryPanel(contentView: hostingView)
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
    
    private func openPanel() {
        guard let panel = panel else { return }
        positionPanel()
        
        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            panel.animator().alphaValue = 1
        }
        
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .keyDown]) { [weak self] event in
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
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.1
            panel?.animator().alphaValue = 0
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
        
        let panelWidth: CGFloat = 350
        let panelHeight: CGFloat = 500
        
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
    
    func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit ClipVault", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem?.popUpMenu(menu)
    }
    
    @objc private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
