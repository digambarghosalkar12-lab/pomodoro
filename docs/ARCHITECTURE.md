# Architecture

Pomodoro Bar is a native AppKit menu-bar application with no external runtime dependencies.

## Components

| Component | Responsibility |
| --- | --- |
| `main.swift` | Application lifecycle, status item, popover, notification authorization and completion alerts |
| `PomodoroTimer.swift` | Timer state machine, phase transitions, persisted count, configurable durations and Shortcut execution |
| `PopoverController.swift` | AppKit controls and circular progress animation |
| `Info.plist` | Bundle identity and menu-bar-only application settings |
| LaunchAgent plist | Starts the application when a user logs in |
| Build scripts | Produce the `.app` and flat installer package |
| JAMF scripts | Download/install, configure, or remove the application |

## Timer state machine

The app starts in Focus. Completing a focus session increments the persistent count and selects a short break, except after every fourth focus session, when it selects a long break. Completing either break returns to Focus. Transitions do not automatically begin the next timer, preventing an unattended Mac from cycling sessions.

Timer accuracy is calculated from an absolute end date instead of counting timer callbacks. This keeps the displayed time accurate when macOS delays callbacks during load or display sleep.

## Data and privacy

The app makes no network requests and includes no analytics. It stores durations and the completion count in the standard preferences domain `com.rabmagid.pomodorobar`. The only subprocess it invokes is `/usr/bin/shortcuts`, using administrator-configurable Shortcut names.

## Focus integration

Apple does not publish an API for a third-party macOS application to enable or disable Focus. The application therefore calls user-owned Apple Shortcuts. This operates in the background through the supported `shortcuts` command and native **Set Focus** action, without Control Center UI scripting.

The app waits for the `shortcuts` command to finish and exposes failure text in the popover. A running timer therefore never implies that Focus was successfully enabled; users can see the automation result directly.
