import AppKit

enum TimerSound: String {
    case focusStart = "focus-start"
    case breakStart = "break-start"
    case focusComplete = "focus-complete"
    case breakComplete = "break-complete"
}

final class SoundPlayer {
    static let shared = SoundPlayer()

    private var sounds: [TimerSound: NSSound] = [:]
    private var currentSound: NSSound?

    private init() {}

    func play(_ sound: TimerSound) {
        let loadedSound: NSSound
        if let cached = sounds[sound] {
            loadedSound = cached
        } else if let url = Bundle.main.url(
            forResource: sound.rawValue,
            withExtension: "wav",
            subdirectory: "Sounds"
        ), let bundled = NSSound(contentsOf: url, byReference: true) {
            sounds[sound] = bundled
            loadedSound = bundled
        } else {
            NSSound.beep()
            return
        }

        currentSound?.stop()
        currentSound = loadedSound
        loadedSound.currentTime = 0
        loadedSound.play()
    }
}
