import AppKit
import SwiftUI

extension Color {
    static let brand = Color(red: 0x7B / 255, green: 0x6E / 255, blue: 0xF6 / 255)
}

// Configures the NSWindow: transparent titlebar, traffic lights, no title text,
// draggable by background, and handles close-to-hide + activation policy.
final class WaveWindowDelegate: NSObject, NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        NSApp.setActivationPolicy(.accessory)
        return false
    }
}

final class ConfiguratorNSView: NSView {
    private let windowDelegate = WaveWindowDelegate()

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window else { return }
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.delegate = windowDelegate
    }
}

struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> ConfiguratorNSView { ConfiguratorNSView() }
    func updateNSView(_ nsView: ConfiguratorNSView, context: Context) {}
}
