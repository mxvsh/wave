import SwiftUI
import Carbon.HIToolbox

struct ShortcutRecorderView: View {
    @Binding var keyCode: UInt16
    @Binding var modifiers: UInt64
    var onRecordingChanged: ((Bool) -> Void)? = nil
    @State private var isRecording = false
    @State private var pendingKeyCode: UInt16? = nil
    @State private var pendingModifiers: UInt64? = nil

    var body: some View {
        Button(action: {
            isRecording.toggle()
            if !isRecording {
                pendingKeyCode = nil
                pendingModifiers = nil
            }
            onRecordingChanged?(isRecording)
        }) {
            HStack(spacing: 6) {
                if isRecording {
                    if let pk = pendingKeyCode, let pm = pendingModifiers {
                        Text("\(KeyCodeMapping.displayString(keyCode: pk, modifiers: CGEventFlags(rawValue: pm)))  ·  Return to save")
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Press shortcut...")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text(KeyCodeMapping.displayString(
                        keyCode: keyCode,
                        modifiers: CGEventFlags(rawValue: modifiers)
                    ))
                }
            }
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isRecording ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .background(isRecording ? ShortcutCaptureRepresentable(
            keyCode: $keyCode,
            modifiers: $modifiers,
            isRecording: $isRecording,
            pendingKeyCode: $pendingKeyCode,
            pendingModifiers: $pendingModifiers,
            onRecordingChanged: onRecordingChanged
        ) : nil)
    }
}

private struct ShortcutCaptureRepresentable: NSViewRepresentable {
    @Binding var keyCode: UInt16
    @Binding var modifiers: UInt64
    @Binding var isRecording: Bool
    @Binding var pendingKeyCode: UInt16?
    @Binding var pendingModifiers: UInt64?
    var onRecordingChanged: ((Bool) -> Void)?

    func makeNSView(context: Context) -> ShortcutCaptureNSView {
        let view = ShortcutCaptureNSView()
        view.onCapture = { code, mods in
            keyCode = code
            modifiers = mods
            pendingKeyCode = nil
            pendingModifiers = nil
            isRecording = false
            onRecordingChanged?(false)
        }
        view.onPending = { code, mods in
            pendingKeyCode = code
            pendingModifiers = mods
        }
        view.onCancel = {
            pendingKeyCode = nil
            pendingModifiers = nil
            isRecording = false
            onRecordingChanged?(false)
        }
        return view
    }

    func updateNSView(_ nsView: ShortcutCaptureNSView, context: Context) {}
}

private final class ShortcutCaptureNSView: NSView {
    var onCapture: ((UInt16, UInt64) -> Void)?
    var onPending: ((UInt16, UInt64) -> Void)?
    var onCancel: (() -> Void)?
    private var monitor: Any?
    private var pendingKeyCode: UInt16?
    private var pendingModifiers: UInt64?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
                guard let self = self else { return event }

                if event.type == .keyDown {
                    if event.keyCode == UInt16(kVK_Escape) {
                        self.pendingKeyCode = nil
                        self.pendingModifiers = nil
                        self.onCancel?()
                    } else if event.keyCode == UInt16(kVK_Return) || event.keyCode == UInt16(kVK_ANSI_KeypadEnter) {
                        // confirm pending single key
                        if let pk = self.pendingKeyCode, let pm = self.pendingModifiers {
                            self.pendingKeyCode = nil
                            self.pendingModifiers = nil
                            self.onCapture?(pk, pm)
                        }
                    } else {
                        let flags = self.captureFlags(from: event)
                        if flags != 0 {
                            // modifier + key → auto-save
                            self.pendingKeyCode = nil
                            self.pendingModifiers = nil
                            self.onCapture?(event.keyCode, flags)
                        } else {
                            // single key → pending, wait for Enter
                            self.pendingKeyCode = event.keyCode
                            self.pendingModifiers = 0
                            self.onPending?(event.keyCode, 0)
                        }
                    }
                    return nil
                }

                if event.type == .flagsChanged,
                   let modifierCapture = self.modifierOnlyCapture(from: event) {
                    // modifier-only → pending, wait for Enter
                    self.pendingKeyCode = modifierCapture.keyCode
                    self.pendingModifiers = modifierCapture.flags
                    self.onPending?(modifierCapture.keyCode, modifierCapture.flags)
                    return nil
                }

                return event
            }
        }
    }

    private func captureFlags(from event: NSEvent) -> UInt64 {
        var flags: UInt64 = 0
        if event.modifierFlags.contains(.control) { flags |= CGEventFlags.maskControl.rawValue }
        if event.modifierFlags.contains(.option) { flags |= CGEventFlags.maskAlternate.rawValue }
        if event.modifierFlags.contains(.shift) { flags |= CGEventFlags.maskShift.rawValue }
        if event.modifierFlags.contains(.command) { flags |= CGEventFlags.maskCommand.rawValue }
        if event.modifierFlags.contains(.function) { flags |= CGEventFlags.maskSecondaryFn.rawValue }
        return flags
    }

    private func modifierOnlyCapture(from event: NSEvent) -> (keyCode: UInt16, flags: UInt64)? {
        let flags = captureFlags(from: event)
        guard flags != 0 else { return nil }
        guard (flags & (flags - 1)) == 0 else { return nil }

        switch Int(event.keyCode) {
        case kVK_Command, kVK_RightCommand:
            return (event.keyCode, CGEventFlags.maskCommand.rawValue)
        case kVK_Control, kVK_RightControl:
            return (event.keyCode, CGEventFlags.maskControl.rawValue)
        case kVK_Option, kVK_RightOption:
            return (event.keyCode, CGEventFlags.maskAlternate.rawValue)
        case kVK_Shift, kVK_RightShift:
            return (event.keyCode, CGEventFlags.maskShift.rawValue)
        case kVK_Function:
            return (event.keyCode, CGEventFlags.maskSecondaryFn.rawValue)
        default:
            return nil
        }
    }

    override func removeFromSuperview() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
        super.removeFromSuperview()
    }
}
