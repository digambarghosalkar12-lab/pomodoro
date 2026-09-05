import AppKit
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private let timer = PomodoroTimer()
    private var controller: PopoverController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        controller = PopoverController(timer: timer)
        popover.contentViewController = controller
        popover.behavior = .transient

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePopover)
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])

        timer.onChange = { [weak self] in
            DispatchQueue.main.async { self?.refresh() }
        }
        timer.onPhaseFinished = { [weak self] phase in
            self?.notify(for: phase)
        }

        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        refresh()
    }

    private func refresh() {
        statusItem.button?.title = "\(timer.statusSymbol) \(timer.timeText)  ·  \(timer.completedFocusSessions)"
        statusItem.button?.toolTip = "Pomodoro Bar — \(timer.phase.title)"
        controller.refresh()
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown { popover.performClose(nil) }
        else { popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY) }
    }

    private func notify(for completedPhase: Phase) {
        NSSound(named: completedPhase == .focus ? "Glass" : "Hero")?.play()
        let content = UNMutableNotificationContent()
        content.title = completedPhase == .focus ? "Focus session complete" : "Break complete"
        content.body = completedPhase == .focus ? "Nice work. Your break is ready." : "Ready for another focused session?"
        content.sound = .default
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
