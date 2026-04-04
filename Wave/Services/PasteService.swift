import AppKit
import ApplicationServices
import Carbon.HIToolbox

struct PasteService {
    static func paste(text: String) {
        pasteViaKeyboard(text)
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
        // Write with ConcealedType so clipboard managers skip recording this transient write
        let item = NSPasteboardItem()
        item.setString(text, forType: .string)
        item.setData(Data(), forType: NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType"))
        pasteboard.writeObjects([item])

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
