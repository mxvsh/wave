import AppKit
import SwiftUI

final class OverlayPanel: NSPanel {
    let overlayState = OverlayState()
    private weak var hosting: NSHostingView<OverlayView>?

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 60),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        hidesOnDeactivate = false
        hasShadow = true
        isMovableByWindowBackground = false

        let hosting = NSHostingView(rootView: OverlayView(overlayState: overlayState))
        hosting.autoresizingMask = [.width, .height]
        self.hosting = hosting
        contentView = hosting
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func showOverlay(status: AppStatus) {
        // Update state first (triggers SwiftUI re-render)
        overlayState.status = status

        // Only reposition and show if not already visible —
        // avoids calling setFrame during an active layout pass.
        guard !isVisible else { return }

        if let screen = NSScreen.main {
            let sf = screen.visibleFrame

            // Get actual content size from hosting view
            let contentSize = hosting?.intrinsicContentSize ?? NSSize(width: 200, height: 48)
            let w = contentSize.width > 0 ? contentSize.width : 200
            let h = contentSize.height > 0 ? contentSize.height : 48

            setFrame(NSRect(x: sf.midX - w / 2, y: sf.minY + 80, width: w, height: h), display: false)
        }
        orderFrontRegardless()
    }

    func hideOverlay() {
        orderOut(nil)
    }
}
