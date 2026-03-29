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
                        Text(KeyCodeMapping.displayString(keyCode: pk, modifiers: CGEventFlags(rawValue: pm)))
                            .foregroundStyle(.primary)
                    } else {
                        Text("Press shortcut…")
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
    private var currentModifierFlags: UInt64 = 0
    // Saved when modifiers are pressed so Enter can confirm even after keys are released
    private var savedCombo: (keyCode: UInt16, flags: UInt64)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
                guard let self = self else { return event }

                if event.type == .keyDown {
                    if event.keyCode == UInt16(kVK_Escape) {
                        self.currentModifierFlags = 0
                        self.savedCombo = nil
                        self.onCancel?()
                    } else if event.keyCode == UInt16(kVK_Return) || event.keyCode == UInt16(kVK_ANSI_KeypadEnter) {
                        // Confirm saved modifier-only combo (user may have released keys before pressing Enter)
                        if let combo = self.savedCombo {
                            self.savedCombo = nil
                            self.currentModifierFlags = 0
                            self.onCapture?(combo.keyCode, combo.flags)
                        }
                    } else {
                        let flags = self.captureFlags(from: event)
                        self.savedCombo = nil
                        self.currentModifierFlags = 0
                        self.onCapture?(event.keyCode, flags)
                    }
                    return nil
                }

                if event.type == .flagsChanged {
                    let newFlags = self.captureFlags(from: event)
                    let addedFlags = newFlags & ~self.currentModifierFlags
                    self.currentModifierFlags = newFlags

                    if addedFlags != 0 {
                        // New modifier pressed — save combo and show as pending
                        self.savedCombo = (keyCode: event.keyCode, flags: newFlags)
                        self.onPending?(event.keyCode, newFlags)
                    }
                    // Don't clear savedCombo on release — user confirms with Enter
                    return nil
                }

                return event
            }
        }
    }

    private func captureFlags(from event: NSEvent) -> UInt64 {
        var flags: UInt64 = 0
        if event.modifierFlags.contains(.control) { flags |= CGEventFlags.maskControl.rawValue }
        if event.modifierFlags.contains(.option)  { flags |= CGEventFlags.maskAlternate.rawValue }
        if event.modifierFlags.contains(.shift)   { flags |= CGEventFlags.maskShift.rawValue }
        if event.modifierFlags.contains(.command) { flags |= CGEventFlags.maskCommand.rawValue }
        if event.modifierFlags.contains(.function) { flags |= CGEventFlags.maskSecondaryFn.rawValue }
        return flags
    }

    override func removeFromSuperview() {
        if let monitor = monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        super.removeFromSuperview()
    }
}
