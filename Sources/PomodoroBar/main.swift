import AppKit
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private let timer = PomodoroTimer()
    private var controller: PopoverController!
    private var statusTrackingArea: NSTrackingArea?
    private var closeWorkItem: DispatchWorkItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        controller = PopoverController(timer: timer)
        controller.onPointerEntered = { [weak self] in self?.cancelScheduledClose() }
        controller.onPointerExited = { [weak self] in self?.scheduleClose() }
        popover.contentViewController = controller
        popover.behavior = .transient

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePopover)
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        if let button = statusItem.button {
            let trackingArea = NSTrackingArea(
                rect: button.bounds,
                options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                owner: self,
                userInfo: nil
            )
            button.addTrackingArea(trackingArea)
            statusTrackingArea = trackingArea
        }

        timer.onChange = { [weak self] in
            DispatchQueue.main.async { self?.refresh() }
        }
        timer.onPhaseFinished = { [weak self] phase in
            self?.notify(for: phase)
        }
        timer.onPhaseStarted = { phase in
            SoundPlayer.shared.play(phase == .focus ? .focusStart : .breakStart)
        }

        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        refresh()
        timer.refreshShortcutConfiguration()
    }

    private func refresh() {
        statusItem.button?.title = "\(timer.statusSymbol) \(timer.timeText)  ·  \(timer.completedFocusSessions)"
        statusItem.button?.toolTip = "Pomodoro Bar — \(timer.phase.title)"
        controller.refresh()
    }

    @objc private func togglePopover() {
        if popover.isShown { closePopover() } else { showPopover() }
    }

    @objc func mouseEntered(with event: NSEvent) {
        cancelScheduledClose()
        showPopover()
    }

    @objc func mouseExited(with event: NSEvent) {
        scheduleClose()
    }

    private func showPopover() {
        guard !popover.isShown, let button = statusItem.button else { return }
        timer.refreshShortcutConfiguration()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    private func closePopover() {
        cancelScheduledClose()
        popover.performClose(nil)
    }

    private func scheduleClose() {
        cancelScheduledClose()
        let workItem = DispatchWorkItem { [weak self] in self?.popover.performClose(nil) }
        closeWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: workItem)
    }

    private func cancelScheduledClose() {
        closeWorkItem?.cancel()
        closeWorkItem = nil
    }

    private func notify(for completedPhase: Phase) {
        SoundPlayer.shared.play(completedPhase == .focus ? .focusComplete : .breakComplete)
        let content = UNMutableNotificationContent()
        content.title = completedPhase == .focus ? "Focus session complete" : "Break complete"
        content.body = completedPhase == .focus ? "Nice work. Your break is ready." : "Ready for another focused session?"
        content.sound = nil
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner])
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
