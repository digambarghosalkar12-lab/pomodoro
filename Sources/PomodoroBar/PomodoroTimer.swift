import Foundation

enum Phase: String {
    case focus, shortBreak, longBreak

    var title: String {
        switch self { case .focus: return "Focus"; case .shortBreak: return "Short Break"; case .longBreak: return "Long Break" }
    }
}

final class PomodoroTimer {
    private(set) var phase: Phase = .focus
    private(set) var isRunning = false
    private(set) var completedFocusSessions = UserDefaults.standard.integer(forKey: "completedFocusSessions")
    private(set) var secondsRemaining: Int
    private(set) var focusStatusText = "Focus automation not checked"
    private(set) var focusStatusIsError = false
    private(set) var shortcutsConfigured = false
    private(set) var shortcutConfigurationChecked = false
    private var ticker: Timer?
    private var endDate: Date?

    var onChange: (() -> Void)?
    var onPhaseFinished: ((Phase) -> Void)?
    var onPhaseStarted: ((Phase) -> Void)?

    init() { secondsRemaining = Self.duration(for: .focus) }

    var duration: Int { Self.duration(for: phase) }
    var progress: Double { duration == 0 ? 0 : 1 - Double(secondsRemaining) / Double(duration) }
    var statusSymbol: String { isRunning ? (phase == .focus ? "◕" : "◔") : "◌" }
    var timeText: String { String(format: "%02d:%02d", secondsRemaining / 60, secondsRemaining % 60) }

    func toggle() { isRunning ? pause() : start() }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        endDate = Date().addingTimeInterval(TimeInterval(secondsRemaining))
        ticker = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in self?.tick() }
        if phase == .focus { setFocus(enabled: true) }
        onPhaseStarted?(phase)
        onChange?()
    }

    func pause() {
        updateRemaining()
        ticker?.invalidate(); ticker = nil
        isRunning = false; endDate = nil
        if phase == .focus { setFocus(enabled: false) }
        onChange?()
    }

    func reset() {
        let wasRunning = isRunning
        stopTicker()
        if wasRunning && phase == .focus { setFocus(enabled: false) }
        secondsRemaining = duration
        onChange?()
    }

    func skip() { finishPhase(notify: false) }

    private func tick() {
        updateRemaining()
        if secondsRemaining <= 0 { finishPhase(notify: true) }
        else { onChange?() }
    }

    private func updateRemaining() {
        guard let endDate else { return }
        secondsRemaining = max(0, Int(ceil(endDate.timeIntervalSinceNow)))
    }

    private func finishPhase(notify: Bool) {
        let completed = phase
        stopTicker()
        if completed == .focus {
            if notify {
                completedFocusSessions += 1
                UserDefaults.standard.set(completedFocusSessions, forKey: "completedFocusSessions")
            }
            phase = notify && completedFocusSessions % 4 == 0 ? .longBreak : .shortBreak
            setFocus(enabled: false)
        } else {
            phase = .focus
        }
        secondsRemaining = duration
        if notify { onPhaseFinished?(completed) }
        onChange?()
    }

    private func stopTicker() {
        ticker?.invalidate(); ticker = nil
        isRunning = false; endDate = nil
    }

    private static func duration(for phase: Phase) -> Int {
        let key: String
        let fallback: Int
        switch phase {
        case .focus: key = "focusMinutes"; fallback = 25
        case .shortBreak: key = "shortBreakMinutes"; fallback = 5
        case .longBreak: key = "longBreakMinutes"; fallback = 15
        }
        let configured = UserDefaults.standard.integer(forKey: key)
        return max(1, configured == 0 ? fallback : configured) * 60
    }

    private func setFocus(enabled: Bool) {
        focusStatusText = enabled ? "Turning Focus on…" : "Turning Focus off…"
        focusStatusIsError = false
        onChange?()
        FocusShortcut.run(enabled: enabled) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                self.focusStatusText = enabled ? "Focus enabled" : "Focus disabled"
                self.focusStatusIsError = false
            case .failure(let message):
                self.focusStatusText = message
                self.focusStatusIsError = true
            }
            self.onChange?()
        }
    }

    func refreshShortcutConfiguration() {
        FocusShortcut.checkConfiguration { [weak self] configured in
            guard let self else { return }
            self.shortcutsConfigured = configured
            self.shortcutConfigurationChecked = true
            self.onChange?()
        }
    }
}

enum FocusShortcut {
    enum Result { case success, failure(String) }
    private static let executionQueue = DispatchQueue(label: "com.company.pomodorobar.focus-shortcuts")

    static func checkConfiguration(completion: @escaping (Bool) -> Void) {
        let defaults = UserDefaults.standard
        let focusOnName = defaults.string(forKey: "focusOnShortcut") ?? "Pomodoro Focus On"
        let focusOffName = defaults.string(forKey: "focusOffShortcut") ?? "Pomodoro Focus Off"
        executionQueue.async {
            let process = Process()
            let outputPipe = Pipe()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
            process.arguments = ["list"]
            process.standardOutput = outputPipe
            process.standardError = FileHandle.nullDevice
            do {
                try process.run()
                process.waitUntilExit()
                let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let names = String(data: data, encoding: .utf8)?
                    .split(whereSeparator: \.isNewline)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? []
                let configured = process.terminationStatus == 0
                    && names.contains(focusOnName)
                    && names.contains(focusOffName)
                DispatchQueue.main.async { completion(configured) }
            } catch {
                DispatchQueue.main.async { completion(false) }
            }
        }
    }

    static func run(enabled: Bool, completion: @escaping (Result) -> Void) {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "runFocusShortcuts") == nil { defaults.set(true, forKey: "runFocusShortcuts") }
        guard defaults.bool(forKey: "runFocusShortcuts") else {
            DispatchQueue.main.async { completion(.failure("Focus automation is disabled")) }
            return
        }
        let key = enabled ? "focusOnShortcut" : "focusOffShortcut"
        let fallback = enabled ? "Pomodoro Focus On" : "Pomodoro Focus Off"
        let name = defaults.string(forKey: key) ?? fallback
        executionQueue.async {
            let process = Process()
            let errorPipe = Pipe()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
            process.arguments = ["run", name]
            process.standardOutput = FileHandle.nullDevice
            process.standardError = errorPipe
            do {
                try process.run()
                process.waitUntilExit()
                if process.terminationStatus == 0 {
                    DispatchQueue.main.async { completion(.success) }
                } else {
                    let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    let detail = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                    let message = detail?.isEmpty == false ? detail! : "Shortcut “\(name)” failed"
                    DispatchQueue.main.async { completion(.failure(message)) }
                }
            } catch {
                DispatchQueue.main.async { completion(.failure("Could not run Shortcut “\(name)”")) }
            }
        }
    }
}
