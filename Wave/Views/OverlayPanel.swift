import AppKit
import QuartzCore

// Idle: tiny pill. Active: expanded wave container.
private let kIdleW:   CGFloat = 44
private let kIdleH:   CGFloat = 22
private let kActiveW: CGFloat = 60
private let kActiveH: CGFloat = 28

// MARK: - Drawing view

private final class OverlayDrawView: NSView {
    var status: AppStatus = .idle { didSet { needsDisplay = true } }
    var audioLevel: Float = 0
    var isAIMode: Bool = false { didSet { needsDisplay = true } }

    private var phase: Double = 0
    private var displayLink: CVDisplayLink?
    private var isAnimating = false

    override var isOpaque: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let b = bounds
        let r = b.height / 2

        // Background + border
        let bg = CGPath(roundedRect: b, cornerWidth: r, cornerHeight: r, transform: nil)
        ctx.setFillColor(CGColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 0.9))
        ctx.addPath(bg); ctx.fillPath()
        ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.1))
        ctx.setLineWidth(0.5)
        ctx.addPath(bg); ctx.strokePath()

        switch status {
        case .idle, .error:
            drawPill(ctx: ctx, bounds: b)
        case .recording, .transcribing:
            drawWave(ctx: ctx, bounds: b)
        }
    }

    private func drawPill(ctx: CGContext, bounds: CGRect) {
        let pw: CGFloat = 20
        let ph: CGFloat = min(3, bounds.height * 0.4)
        let px = (bounds.width - pw) / 2
        let py = (bounds.height - ph) / 2
        let path = CGPath(roundedRect: CGRect(x: px, y: py, width: pw, height: ph),
                          cornerWidth: ph / 2, cornerHeight: ph / 2, transform: nil)
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.35))
        ctx.addPath(path); ctx.fillPath()
    }

    private func drawWave(ctx: CGContext, bounds: CGRect) {
        let barCount = 9
        let barW: CGFloat  = 3
        let spacing: CGFloat = 2.5
        let totalW = CGFloat(barCount) * barW + CGFloat(barCount - 1) * spacing
        let startX = (bounds.width - totalW) / 2
        let centerY = bounds.height / 2
        let maxH = bounds.height * 0.75
        let minH: CGFloat = 2
        let level = max(0.08, CGFloat(audioLevel))

        for i in 0..<barCount {
            let norm = Double(i) / Double(barCount - 1)
            let shape = CGFloat(sin(phase + norm * .pi * 2.0) * 0.4 + 0.6)
            let h = minH + (maxH - minH) * level * shape
            let barX = startX + CGFloat(i) * (barW + spacing)
            let rect = CGRect(x: barX, y: centerY - h / 2, width: barW, height: h)
            let path = CGPath(roundedRect: rect, cornerWidth: barW / 2, cornerHeight: barW / 2, transform: nil)
            let t = CGFloat(i) / CGFloat(barCount - 1)
            let color: CGColor = isAIMode
                ? CGColor(red: 0.42 + t * 0.2, green: 0.52 - t * 0.1, blue: 1.0, alpha: 1.0)
                : CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.85)
            ctx.setFillColor(color)
            ctx.addPath(path); ctx.fillPath()
        }
    }

    func startAnimation() {
        guard !isAnimating else { return }
        isAnimating = true
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        guard let dl = displayLink else { return }
        let view = self
        CVDisplayLinkSetOutputHandler(dl) { _, _, _, _, _ in
            DispatchQueue.main.async {
                switch view.status {
                case .recording, .transcribing:
                    view.phase += 0.04
                    view.needsDisplay = true
                default: break
                }
            }
            return kCVReturnSuccess
        }
        CVDisplayLinkStart(dl)
    }

    func stopAnimation() {
        isAnimating = false
        if let dl = displayLink { CVDisplayLinkStop(dl) }
        displayLink = nil
    }

    deinit { stopAnimation() }
}

// MARK: - Panel

final class OverlayPanel: NSPanel {
    private let drawView = OverlayDrawView()
    private var baseY: CGFloat = 0
    private var baseCenterX: CGFloat = 0

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: kIdleW, height: kIdleH),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        hidesOnDeactivate = false
        hasShadow = false
        isMovableByWindowBackground = false
        ignoresMouseEvents = true

        drawView.frame = NSRect(x: 0, y: 0, width: kIdleW, height: kIdleH)
        drawView.autoresizingMask = [.width, .height]
        contentView = drawView
        drawView.startAnimation()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func updateStatus(_ status: AppStatus) {
        drawView.status = status

        if !isVisible {
            positionOnScreen()
            orderFrontRegardless()
        }

        let isActive: Bool
        switch status {
        case .recording, .transcribing: isActive = true
        default: isActive = false
        }

        let w = isActive ? kActiveW : kIdleW
        let h = isActive ? kActiveH : kIdleH
        let targetFrame = NSRect(x: baseCenterX - w / 2, y: baseY, width: w, height: h)

        DispatchQueue.main.async { [weak self] in
            self?.setFrame(targetFrame, display: true, animate: true)
        }
    }

    func setAudioLevel(_ level: Float) {
        drawView.audioLevel = level
    }

    func setAIMode(_ enabled: Bool) {
        drawView.isAIMode = enabled
    }

    @objc private func screenDidChange() { positionOnScreen() }

    private func positionOnScreen() {
        guard let screen = NSScreen.main else { return }
        let visibleFrame = screen.visibleFrame
        let screenFrame = screen.frame

        baseCenterX = screenFrame.midX
        baseY = visibleFrame.minY > screenFrame.minY
            ? visibleFrame.minY + 8
            : screenFrame.minY + 12

        let w = frame.width > kIdleW ? kActiveW : kIdleW
        let h = frame.height > kIdleH ? kActiveH : kIdleH
        setFrame(NSRect(x: baseCenterX - w / 2, y: baseY, width: w, height: h), display: true)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
