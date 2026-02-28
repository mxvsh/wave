import Carbon.HIToolbox

struct KeyCodeMapping {
    static func displayName(for keyCode: UInt16) -> String {
        switch Int(keyCode) {
        case kVK_ANSI_A: return "A"
        case kVK_ANSI_S: return "S"
        case kVK_ANSI_D: return "D"
        case kVK_ANSI_F: return "F"
        case kVK_ANSI_H: return "H"
        case kVK_ANSI_G: return "G"
        case kVK_ANSI_Z: return "Z"
        case kVK_ANSI_X: return "X"
        case kVK_ANSI_C: return "C"
        case kVK_ANSI_V: return "V"
        case kVK_ANSI_B: return "B"
        case kVK_ANSI_Q: return "Q"
        case kVK_ANSI_W: return "W"
        case kVK_ANSI_E: return "E"
        case kVK_ANSI_R: return "R"
        case kVK_ANSI_Y: return "Y"
        case kVK_ANSI_T: return "T"
        case kVK_ANSI_1: return "1"
        case kVK_ANSI_2: return "2"
        case kVK_ANSI_3: return "3"
        case kVK_ANSI_4: return "4"
        case kVK_ANSI_6: return "6"
        case kVK_ANSI_5: return "5"
        case kVK_ANSI_9: return "9"
        case kVK_ANSI_7: return "7"
        case kVK_ANSI_8: return "8"
        case kVK_ANSI_0: return "0"
        case kVK_ANSI_O: return "O"
        case kVK_ANSI_U: return "U"
        case kVK_ANSI_I: return "I"
        case kVK_ANSI_P: return "P"
        case kVK_ANSI_L: return "L"
        case kVK_ANSI_J: return "J"
        case kVK_ANSI_K: return "K"
        case kVK_ANSI_N: return "N"
        case kVK_ANSI_M: return "M"
        case kVK_Return: return "Return"
        case kVK_Tab: return "Tab"
        case kVK_Space: return "Space"
        case kVK_Delete: return "Delete"
        case kVK_Escape: return "Esc"
        case kVK_Command: return "Cmd"
        case kVK_Shift: return "Shift"
        case kVK_CapsLock: return "CapsLock"
        case kVK_Option: return "Option"
        case kVK_Control: return "Control"
        case kVK_RightCommand: return "Right Cmd"
        case kVK_RightShift: return "Right Shift"
        case kVK_RightOption: return "Right Option"
        case kVK_RightControl: return "Right Control"
        case kVK_Function: return "Fn"
        case kVK_F1: return "F1"
        case kVK_F2: return "F2"
        case kVK_F3: return "F3"
        case kVK_F4: return "F4"
        case kVK_F5: return "F5"
        case kVK_F6: return "F6"
        case kVK_F7: return "F7"
        case kVK_F8: return "F8"
        case kVK_F9: return "F9"
        case kVK_F10: return "F10"
        case kVK_F11: return "F11"
        case kVK_F12: return "F12"
        case kVK_ForwardDelete: return "Fwd Delete"
        case kVK_Home: return "Home"
        case kVK_End: return "End"
        case kVK_PageUp: return "Page Up"
        case kVK_PageDown: return "Page Down"
        case kVK_LeftArrow: return "Left"
        case kVK_RightArrow: return "Right"
        case kVK_DownArrow: return "Down"
        case kVK_UpArrow: return "Up"
        default: return "Key \(keyCode)"
        }
    }

    static func modifierNames(for flags: CGEventFlags) -> [String] {
        var names: [String] = []
        if flags.contains(.maskControl) { names.append("Control") }
        if flags.contains(.maskAlternate) { names.append("Option") }
        if flags.contains(.maskShift) { names.append("Shift") }
        if flags.contains(.maskCommand) { names.append("Cmd") }
        if flags.contains(.maskSecondaryFn) { names.append("Fn") }
        return names
    }

    static func displayString(keyCode: UInt16, modifiers: CGEventFlags) -> String {
        let mods = modifierNames(for: modifiers)
        let key = displayName(for: keyCode)
        if isModifierKey(keyCode), mods.count == 1 {
            return key
        }
        return (mods + [key]).joined(separator: " + ")
    }

    private static func isModifierKey(_ keyCode: UInt16) -> Bool {
        switch Int(keyCode) {
        case kVK_Command, kVK_RightCommand, kVK_Control, kVK_RightControl, kVK_Option, kVK_RightOption, kVK_Shift, kVK_RightShift, kVK_Function:
            return true
        default:
            return false
        }
    }
}
