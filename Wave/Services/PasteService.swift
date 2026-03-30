import AppKit
import ApplicationServices
import Carbon.HIToolbox

struct PasteService {
    static func paste(text: String) {
        // Try AX insertion first — works in native AppKit fields without touching clipboard
        if pasteViaAX(text: text) { return }
        // Fall back to clipboard + Cmd+V — works everywhere (Terminal, web, Electron, etc.)
        pasteViaKeyboard(text: text)
    }

    @discardableResult
    private static func pasteViaAX(_ text: String) -> Bool {
        let systemWide = AXUIElementCreateSystemWide()
        var focusedElement: CFTypeRef?
        guard AXUIElementCopyAttributeValue(systemWide, kAXFocusedUIElementAttribute as CFString, &focusedElement) == .success,
              let element = focusedElement else { return false }
        let result = AXUIElementSetAttributeValue(element as! AXUIElement, kAXSelectedTextAttribute as CFString, text as CFString)
        return result == .success
    }

    private static func pasteViaKeyboard(_ text: String) {
        let pasteboard = NSPasteboard.general

        // Preserve whatever was on the clipboard
        let previousItems = pasteboard.pasteboardItems?.compactMap { item -> [NSPasteboard.PasteboardType: Data]? in
            var dataMap: [NSPasteboard.PasteboardType: Data] = [:]
            for type in item.types {
                if let data = item.data(forType: type) { dataMap[type] = data }
            }
            return dataMap.isEmpty ? nil : dataMap
        }

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Simulate Cmd+V
        let src = CGEventSource(stateID: .hidSystemState)
        let vKey = CGKeyCode(kVK_ANSI_V)
        let down = CGEvent(keyboardEventSource: src, virtualKey: vKey, keyDown: true)
        let up   = CGEvent(keyboardEventSource: src, virtualKey: vKey, keyDown: false)
        down?.flags = .maskCommand
        up?.flags   = .maskCommand
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)

        // Restore clipboard after the keystroke has been processed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            pasteboard.clearContents()
            if let items = previousItems, !items.isEmpty {
                for dataMap in items {
                    let newItem = NSPasteboardItem()
                    for (type, data) in dataMap { newItem.setData(data, forType: type) }
                    pasteboard.writeObjects([newItem])
                }
            }
        }
    }

    static func getSelectedText() -> String? {
        let systemWide = AXUIElementCreateSystemWide()
        var focusedElement: CFTypeRef?
        guard AXUIElementCopyAttributeValue(systemWide, kAXFocusedUIElementAttribute as CFString, &focusedElement) == .success,
              let element = focusedElement else { return nil }
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element as! AXUIElement, kAXSelectedTextAttribute as CFString, &value) == .success,
              let text = value as? String, !text.isEmpty else { return nil }
        return text
    }
}
