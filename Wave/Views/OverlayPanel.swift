import AppKit
import QuartzCore

// Idle: tiny pill. Active: expanded wave container.
private let kIdleW:    CGFloat = 44
private let kIdleH:    CGFloat = 22
private let kActiveW:  CGFloat = 60
private let kActiveH:  CGFloat = 28
private let kHoverW:   CGFloat = 54   // slight width expansion on hover

// MARK: - Tooltip panel

private final class TooltipPanel: NSPanel {
    private let label = NSTextField(labelWithString: "")

    init() {
        super.init(
            contentRect: .zero,
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
        ignoresMouseEvents = true

        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.85)
        label.isBezeled = false
        label.drawsBackground = false
        label.alignment = .center

        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = CGColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 0.9)
        container.layer?.cornerRadius = 6
        container.layer?.borderColor = CGColor(red: 1, green: 1, blue: 1, alpha: 0.1)
        container.layer?.borderWidth = 0.5
        container.addSubview(label)
        contentView = container
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func show(text: String, above pillFrame: NSRect) {
        label.stringValue = text
        label.sizeToFit()

        let padding: CGFloat = 10
        let w = label.frame.width + padding * 2
        let h: CGFloat = 22
        let x = pillFrame.midX - w / 2
        let y = pillFrame.maxY + 6

        setFrame(NSRect(x: x, y: y, width: w, height: h), display: false)

        if let container = contentView {
            label.frame = NSRect(x: padding, y: (h - label.frame.height) / 2,
                                 width: label.frame.width, height: label.frame.height)
            container.frame = NSRect(x: 0, y: 0, width: w, height: h)
        }

        orderFrontRegardless()
    }

    func hide() {
        orderOut(nil)
    }
}

// MARK: - Drawing view

private final class OverlayDrawView: NSView {
    var status: AppStatus = .idle { didSet { needsDisplay = true; updateTracking() } }
    var audioLevel: Float = 0
    var isAIMode: Bool = false { didSet { needsDisplay = true } }
    var isHovered: Bool = false { didSet { needsDisplay = true; onHoverChanged?(isHovered) } }
    var onHoverChanged: ((Bool) -> Void)?
    var onMouseDown: (() -> Void)?
    var onMouseUp: (() -> Void)?

    private var phase: Double = 0
    private var displayLink: CVDisplayLink?
    private var isAnimating = false
    private var trackingArea: NSTrackingArea?

    override var isOpaque: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let b = bounds
        let r = b.height / 2

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
        let alpha: CGFloat = isHovered ? 0.6 : 0.35
        let path = CGPath(roundedRect: CGRect(x: px, y: py, width: pw, height: ph),
                          cornerWidth: ph / 2, cornerHeight: ph / 2, transform: nil)
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: alpha))
        ctx.addPath(path); ctx.fillPath()
    }

    private func updateTracking() {
        if let area = trackingArea { removeTrackingArea(area) }
        guard status == .idle else { trackingArea = nil; return }
        let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self, userInfo: nil)
        addTrackingArea(area)
        trackingArea = area
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        updateTracking()
    }

    override func mouseEntered(with event: NSEvent) {
        guard status == .idle else { return }
        isHovered = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        guard status == .idle else { return }
        onMouseDown?()
    }

    override func mouseUp(with event: NSEvent) {
        onMouseUp?()
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
    private let tooltipPanel = TooltipPanel()
    private var baseY: CGFloat = 0
    private var baseCenterX: CGFloat = 0
    private var shortcutLabel: String = ""
    private var tooltipTimer: Timer?

    var onMouseDown: (() -> Void)? {
        get { drawView.onMouseDown }
        set { drawView.onMouseDown = newValue }
    }
    var onMouseUp: (() -> Void)? {
        get { drawView.onMouseUp }
        set { drawView.onMouseUp = newValue }
    }
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
        ignoresMouseEvents = false

        drawView.frame = NSRect(x: 0, y: 0, width: kIdleW, height: kIdleH)
        drawView.autoresizingMask = [.width, .height]
        contentView = drawView
        drawView.startAnimation()

        drawView.onHoverChanged = { [weak self] hovered in
            self?.handleHoverChange(hovered)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func setShortcutLabel(_ label: String) {
        shortcutLabel = label
    }

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

        if isActive {
            tooltipTimer?.invalidate()
            tooltipTimer = nil
            tooltipPanel.hide()
        }
        ignoresMouseEvents = isActive

        let w = isActive ? kActiveW : kIdleW
        let h = isActive ? kActiveH : kIdleH
        let targetFrame = NSRect(x: baseCenterX - w / 2, y: baseY, width: w, height: h)

        DispatchQueue.main.async { [weak self] in
            self?.setFrame(targetFrame, display: true, animate: true)
        }
    }

    private func handleHoverChange(_ hovered: Bool) {
        guard drawView.status == .idle else { return }

        if hovered {
            let targetFrame = NSRect(x: baseCenterX - kHoverW / 2, y: baseY, width: kHoverW, height: kIdleH)
            setFrame(targetFrame, display: true, animate: true)
            tooltipTimer?.invalidate()
            tooltipTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
                guard let self, self.drawView.isHovered else { return }
                self.tooltipPanel.show(text: "Hold to speak", above: self.frame)
            }
        } else {
            tooltipTimer?.invalidate()
            tooltipTimer = nil
            tooltipPanel.hide()
            let targetFrame = NSRect(x: baseCenterX - kIdleW / 2, y: baseY, width: kIdleW, height: kIdleH)
            setFrame(targetFrame, display: true, animate: true)
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
