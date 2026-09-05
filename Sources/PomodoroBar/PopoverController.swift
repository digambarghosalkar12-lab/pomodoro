import AppKit

final class HoverAwareView: NSView {
    var onPointerEntered: (() -> Void)?
    var onPointerExited: (() -> Void)?
    private var hoverTrackingArea: NSTrackingArea?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let hoverTrackingArea { removeTrackingArea(hoverTrackingArea) }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        hoverTrackingArea = area
    }

    override func mouseEntered(with event: NSEvent) { onPointerEntered?() }
    override func mouseExited(with event: NSEvent) { onPointerExited?() }
}

final class ProgressRingView: NSView {
    var progress = 0.0 { didSet { needsDisplay = true } }
    var phase: Phase = .focus { didSet { needsDisplay = true } }

    override func draw(_ dirtyRect: NSRect) {
        let rect = bounds.insetBy(dx: 7, dy: 7)
        let center = NSPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        NSColor.separatorColor.withAlphaComponent(0.35).setStroke()
        let track = NSBezierPath(ovalIn: rect); track.lineWidth = 8; track.stroke()
        let path = NSBezierPath()
        path.appendArc(withCenter: center, radius: radius, startAngle: 90, endAngle: 90 - 360 * progress, clockwise: true)
        path.lineWidth = 8; path.lineCapStyle = .round
        (phase == .focus ? NSColor.systemRed : NSColor.systemGreen).setStroke()
        path.stroke()
    }
}

final class PopoverController: NSViewController {
    private let timer: PomodoroTimer
    private let ring = ProgressRingView()
    private let timeLabel = NSTextField(labelWithString: "")
    private let phaseLabel = NSTextField(labelWithString: "")
    private let countLabel = NSTextField(labelWithString: "")
    private let focusLabel = NSTextField(wrappingLabelWithString: "")
    private let startButton = NSButton(title: "Start", target: nil, action: nil)
    private let shortcutsButton = NSButton(title: "Set Up Focus", target: nil, action: nil)

    var onPointerEntered: (() -> Void)?
    var onPointerExited: (() -> Void)?

    init(timer: PomodoroTimer) { self.timer = timer; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func loadView() {
        let hoverView = HoverAwareView(frame: NSRect(x: 0, y: 0, width: 290, height: 330))
        hoverView.onPointerEntered = { [weak self] in self?.onPointerEntered?() }
        hoverView.onPointerExited = { [weak self] in self?.onPointerExited?() }
        view = hoverView
        phaseLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        phaseLabel.alignment = .center
        timeLabel.font = .monospacedDigitSystemFont(ofSize: 34, weight: .medium)
        timeLabel.alignment = .center
        countLabel.textColor = .secondaryLabelColor
        countLabel.alignment = .center
        focusLabel.font = .systemFont(ofSize: 11)
        focusLabel.alignment = .center
        startButton.bezelStyle = .rounded
        startButton.keyEquivalent = " "
        startButton.target = self; startButton.action = #selector(toggle)

        let reset = NSButton(title: "Reset", target: self, action: #selector(resetTimer))
        let skip = NSButton(title: "Skip", target: self, action: #selector(skipTimer))
        shortcutsButton.target = self; shortcutsButton.action = #selector(openShortcuts)
        [reset, skip, shortcutsButton].forEach { $0.bezelStyle = .rounded }
        let controls = NSStackView(views: [reset, startButton, skip])
        controls.orientation = .horizontal; controls.spacing = 8; controls.distribution = .fillEqually
        let stack = NSStackView(views: [phaseLabel, ring, timeLabel, countLabel, controls, focusLabel, shortcutsButton])
        stack.orientation = .vertical; stack.spacing = 10; stack.alignment = .centerX
        stack.translatesAutoresizingMaskIntoConstraints = false
        [phaseLabel, timeLabel, countLabel, controls, focusLabel].forEach { $0.widthAnchor.constraint(equalToConstant: 250).isActive = true }
        ring.widthAnchor.constraint(equalToConstant: 105).isActive = true
        ring.heightAnchor.constraint(equalToConstant: 105).isActive = true
        view.addSubview(stack)
        NSLayoutConstraint.activate([stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20), stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20), stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 16)])
        refresh()
    }

    func refresh() {
        guard isViewLoaded else { return }
        phaseLabel.stringValue = timer.phase.title
        timeLabel.stringValue = timer.timeText
        countLabel.stringValue = "\(timer.completedFocusSessions) focus session\(timer.completedFocusSessions == 1 ? "" : "s") completed"
        startButton.title = timer.isRunning ? "Pause" : "Start"
        ring.phase = timer.phase; ring.progress = timer.progress
        focusLabel.stringValue = timer.focusStatusText
        focusLabel.textColor = timer.focusStatusIsError ? .systemRed : .secondaryLabelColor
        shortcutsButton.isHidden = timer.shortcutConfigurationChecked && timer.shortcutsConfigured
    }

    @objc private func toggle() { timer.toggle() }
    @objc private func resetTimer() { timer.reset() }
    @objc private func skipTimer() { timer.skip() }
    @objc private func openShortcuts() {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Set Up Focus Shortcuts"
        alert.informativeText = "Import both Apple-approved Shortcuts to let Pomodoro Bar control Do Not Disturb securely in the background. macOS requires you to review and approve each import."
        alert.icon = NSApp.applicationIconImage
        alert.addButton(withTitle: "Import Focus On")
        alert.addButton(withTitle: "Import Focus Off")
        alert.addButton(withTitle: "Open Shortcuts")
        alert.addButton(withTitle: "Cancel")

        let instructions = NSTextField(wrappingLabelWithString: """
        1. Select “Import Focus On”, then review and add it in Shortcuts.

        2. Open this setup again and select “Import Focus Off”.

        3. Run each Shortcut once and approve any request.

        The setup button disappears after both Shortcuts are installed. Pomodoro Bar never imports a Shortcut without your action.
        """)
        instructions.font = .systemFont(ofSize: 12)
        instructions.textColor = .labelColor
        instructions.frame = NSRect(x: 0, y: 0, width: 390, height: 155)
        alert.accessoryView = instructions

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            openBundledShortcut(named: "Pomodoro Focus On")
        case .alertSecondButtonReturn:
            openBundledShortcut(named: "Pomodoro Focus Off")
        case .alertThirdButtonReturn:
            if let url = URL(string: "shortcuts://") { NSWorkspace.shared.open(url) }
        default:
            break
        }
    }

    private func openBundledShortcut(named name: String) {
        guard let url = Bundle.main.url(
            forResource: name,
            withExtension: "shortcut",
            subdirectory: "Shortcuts"
        ) else {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "Shortcut file not found"
            alert.informativeText = "Reinstall Pomodoro Bar or ask your administrator to verify the application package."
            alert.runModal()
            return
        }
        NSWorkspace.shared.open(url)
    }
}
