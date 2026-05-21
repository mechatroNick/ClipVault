import AppKit

let event = CGEvent(keyboardEventSource: nil, virtualKey: 43, keyDown: true)!
event.flags = .maskCommand
let nsEvent = NSEvent(cgEvent: event)
print("chars:", nsEvent?.characters)
print("charsIgMod:", nsEvent?.charactersIgnoringModifiers)
print("keyCode:", nsEvent?.keyCode)
