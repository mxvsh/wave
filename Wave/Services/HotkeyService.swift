import Foundation
import CoreGraphics
import Carbon.HIToolbox

final class HotkeyService {
    var targetKeyCode: CGKeyCode = CGKeyCode(kVK_Space)
    var targetModifiers: CGEventFlags = .maskControl
    var onKeyDown: (() -> Void)?
    var onKeyUp: (() -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var modifierShortcutIsPressed = false

    func start() {
        modifierShortcutIsPressed = false
        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.flagsChanged.rawValue)

        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            guard let refcon = refcon else { return Unmanaged.passRetained(event) }
            let service = Unmanaged<HotkeyService>.fromOpaque(refcon).takeUnretainedValue()
            return service.handleEvent(proxy: proxy, type: type, event: event)
        }

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: callback,
            userInfo: selfPtr
        ) else {
            print("Failed to create event tap. Check Accessibility permissions.")
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func stop() {
        modifierShortcutIsPressed = false
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
            }
        }
        eventTap = nil
        runLoopSource = nil
    }

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passRetained(event)
        }

        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags

        let relevantFlags: CGEventFlags = [.maskControl, .maskAlternate, .maskShift, .maskCommand, .maskSecondaryFn]
        let currentMods = flags.intersection(relevantFlags)
        let targetMods = targetModifiers.intersection(relevantFlags)
        let isModifierOnlyShortcut = isModifierKey(targetKeyCode)

        if isModifierOnlyShortcut {
            guard type == .flagsChanged else {
                return Unmanaged.passRetained(event)
            }

            guard keyCode == targetKeyCode else {
                return Unmanaged.passRetained(event)
            }

            let isPressed = currentMods == targetMods && !currentMods.isEmpty
            if isPressed && !modifierShortcutIsPressed {
                modifierShortcutIsPressed = true
                onKeyDown?()
                return nil
            }

            if !isPressed && modifierShortcutIsPressed {
                modifierShortcutIsPressed = false
                onKeyUp?()
                return nil
            }

            return Unmanaged.passRetained(event)
        }

        guard keyCode == targetKeyCode && currentMods == targetMods else {
            return Unmanaged.passRetained(event)
        }

        if type == .keyDown {
            onKeyDown?()
            return nil // suppress the event
        } else if type == .keyUp {
            onKeyUp?()
            return nil
        }

        return Unmanaged.passRetained(event)
    }

    deinit {
        stop()
    }

    private func isModifierKey(_ keyCode: CGKeyCode) -> Bool {
        switch Int(keyCode) {
        case kVK_Command, kVK_RightCommand, kVK_Control, kVK_RightControl, kVK_Option, kVK_RightOption, kVK_Shift, kVK_RightShift, kVK_Function:
            return true
        default:
            return false
        }
    }
}
