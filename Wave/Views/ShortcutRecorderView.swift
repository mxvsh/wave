import SwiftUI
import Carbon.HIToolbox

struct ShortcutRecorderView: View {
    @Binding var keyCode: UInt16
    @Binding var modifiers: UInt64
    @State private var isRecording = false

    var body: some View {
        Button(action: { isRecording.toggle() }) {
            HStack(spacing: 6) {
                if isRecording {
                    Text("Press shortcut...")
                        .foregroundStyle(.secondary)
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
            isRecording: $isRecording
        ) : nil)
    }
}

private struct ShortcutCaptureRepresentable: NSViewRepresentable {
    @Binding var keyCode: UInt16
    @Binding var modifiers: UInt64
    @Binding var isRecording: Bool

    func makeNSView(context: Context) -> ShortcutCaptureNSView {
        let view = ShortcutCaptureNSView()
        view.onCapture = { code, mods in
            keyCode = code
            modifiers = mods
            isRecording = false
        }
        view.onCancel = {
            isRecording = false
        }
        return view
    }

    func updateNSView(_ nsView: ShortcutCaptureNSView, context: Context) {}
}

private final class ShortcutCaptureNSView: NSView {
    var onCapture: ((UInt16, UInt64) -> Void)?
    var onCancel: (() -> Void)?
    private var monitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
                guard let self = self else { return event }

                if event.type == .keyDown {
                    if event.keyCode == UInt16(kVK_Escape) {
                        self.onCancel?()
                    } else {
                        self.onCapture?(event.keyCode, self.captureFlags(from: event))
                    }
                    return nil
                }

                if event.type == .flagsChanged,
                   let modifierCapture = self.modifierOnlyCapture(from: event) {
                    self.onCapture?(modifierCapture.keyCode, modifierCapture.flags)
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
        guard (flags & (flags - 1)) == 0 else { return nil } // exactly one modifier bit set

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
