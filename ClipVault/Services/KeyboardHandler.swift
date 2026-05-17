//
//  KeyboardHandler.swift
//  ClipVault
//

import AppKit
import Carbon

@MainActor
final class KeyboardHandler {
    static let shared = KeyboardHandler()
    
    private var hotKeyRef: EventHotKeyRef?
    var onHotKey: (() -> Void)?
    
    private init() {}
    
    func registerHotKey() {
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(32) // " " 
        hotKeyID.id = UInt32(1)
        
        let modifiers = UInt32(cmdKey | shiftKey)
        let keyCode = UInt32(kVK_ANSI_V)
        
        var eventHandler: EventHandlerRef?
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        let status = InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, event, userData) -> OSStatus in
            Task { @MainActor in
                KeyboardHandler.shared.onHotKey?()
            }
            return noErr
        }, 1, &eventType, nil, &eventHandler)
        
        if status == noErr {
            RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        }
    }
    
    func unregisterHotKey() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }
}
