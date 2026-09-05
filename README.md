# Pomodoro Bar for macOS

Pomodoro Bar is a lightweight native macOS menu-bar timer built for individual use and JAMF-managed fleets. It follows the classic Pomodoro technique, shows the countdown without opening a window, and integrates with macOS notifications and Focus through Apple Shortcuts.

## Features

- Live `MM:SS` countdown in the top-right menu bar
- Completed focus-session count beside the timer
- 25-minute focus and 5-minute break cycle
- 15-minute long break after every fourth completed focus session
- Animated circular progress indicator
- Start, pause, reset, and skip controls
- Audible completion alerts and native macOS notifications
- Focus enable/disable integration through configurable Apple Shortcuts
- Persistent completed-session count
- Configurable durations through macOS defaults or a JAMF policy
- Launch-at-login support for all users
- Immediate startup for the signed-in user after package installation
- No analytics, accounts, external frameworks, or network traffic

## Requirements

- macOS 13 Ventura or newer
- Xcode Command Line Tools with a matching macOS SDK for building
- Swift 5.9 or newer
- Apple Shortcuts for automatic Focus/DND integration
- JAMF Pro only when deploying to managed Macs

## Project structure

```text
.
├── Package.swift
├── Resources
│   ├── Info.plist
│   ├── AppIcon-1024.png
│   ├── AppIcon.icns
│   └── com.company.pomodorobar.plist
├── Sources/PomodoroBar
│   ├── PomodoroTimer.swift
│   ├── PopoverController.swift
│   └── main.swift
├── docs
│   ├── ARCHITECTURE.md
│   └── JAMF.md
└── scripts
    ├── build-app.sh
    ├── build-pkg.sh
    ├── configure-managed-defaults.sh
    ├── jamf-deploy.sh
    ├── jamf-uninstall.sh
    └── pkg-scripts/postinstall
```

See [Architecture](docs/ARCHITECTURE.md) for component and privacy details and [JAMF deployment](docs/JAMF.md) for fleet procedures.

## Build locally

Clone the repository and run:

```sh
chmod +x scripts/*.sh
./scripts/build-app.sh
```

The application is created at `dist/Pomodoro Bar.app`. For a local test:

```sh
open "dist/Pomodoro Bar.app"
```

Do not run the build scripts with `sudo`; doing so leaves root-owned artifacts in the repository. To use a different output directory, set `DIST_DIR` when running `build-app.sh`.

To produce the installer package:

```sh
VERSION=1.0.0 ./scripts/build-pkg.sh
```

The package is created at `dist/PomodoroBar-1.0.0.pkg`.

### Production signing

The default build uses ad-hoc app signing and is intended only for local testing. For managed production deployment, sign with an Apple Developer ID Application certificate:

```sh
CODE_SIGN_IDENTITY="Developer ID Application: Example Corp (TEAMID1234)" \
  VERSION=1.0.0 ./scripts/build-pkg.sh
productsign --sign "Developer ID Installer: Example Corp (TEAMID1234)" \
  dist/PomodoroBar-1.0.0.pkg dist/PomodoroBar-1.0.0-signed.pkg
pkgutil --check-signature dist/PomodoroBar-1.0.0-signed.pkg
```

Notarize the signed package if it will be distributed outside your managed environment. Replace the example identities and Team ID with your organization’s values.

## Using the app

1. Select the timer in the menu bar.
2. Select **Start** to begin a focus session.
3. Select **Pause** to pause, **Reset** to restart the current phase, or **Skip** to move to the next phase.
4. At completion, macOS plays a sound, posts a notification, and prepares the correct break or focus phase.

The menu-bar symbol indicates whether the timer is idle, focusing, or on a break. The number after the separator is the total number of completed focus sessions stored for that user.

## Configure Focus mode

macOS does not provide a supported public API for third-party applications to toggle Focus directly. Pomodoro Bar runs Apple Shortcuts in the background. It does not use Accessibility, simulate keyboard or mouse input, or open Control Center.

For the Shortcuts method, create these shortcuts in the Shortcuts app:

1. **Pomodoro Focus On**: add **Set Focus**, select your work Focus, and set it to remain on until turned off.
2. **Pomodoro Focus Off**: add **Set Focus** and configure the selected Focus to turn off.

Users can select **Open Shortcuts** in the Pomodoro Bar popover. The app displays these setup instructions before opening Apple Shortcuts, including the exact required names and actions.

Focus is enabled when a focus timer starts. It is disabled when the timer is paused, reset, skipped, or completed. Break timers leave Focus disabled so normal macOS notifications appear.

Use different Shortcut names if required:

```sh
defaults write com.company.pomodorobar focusOnShortcut "Company Focus On"
defaults write com.company.pomodorobar focusOffShortcut "Company Focus Off"
```

Disable integration entirely with:

```sh
defaults write com.company.pomodorobar runFocusShortcuts -bool false
```

## Configure timer durations

```sh
defaults write com.company.pomodorobar focusMinutes -int 25
defaults write com.company.pomodorobar shortBreakMinutes -int 5
defaults write com.company.pomodorobar longBreakMinutes -int 15
```

Values must be whole minutes. Restart the app after changing defaults to ensure the current phase reloads the new duration. JAMF administrators can use `scripts/configure-managed-defaults.sh` instead.

## JAMF deployment

The recommended approach is to upload the signed package to JAMF Pro and install it through a Computer Policy. Alternatively, `scripts/jamf-deploy.sh` downloads a package from HTTPS, verifies its signature and optional Team ID, installs it, and opens the app for the current console user.

The installer loads the LaunchAgent immediately when a user is signed in. At subsequent logins, macOS loads the app automatically. It cannot display at the FileVault or login window because menu-bar applications require an authenticated GUI user session.

| JAMF parameter | Description |
| --- | --- |
| 4 | HTTPS URL of the installer package; required |
| 5 | Expected signing Team ID; recommended |

Detailed policy, configuration, rollback, and inventory guidance is available in [docs/JAMF.md](docs/JAMF.md).

## Uninstall

For JAMF, add `scripts/jamf-uninstall.sh` to a Computer Policy. Parameter 4 controls preference removal:

- Empty or `false`: preserve each user’s completion count and settings.
- `true`: remove settings and completion history for local users as well.

Run manually as an administrator if needed:

```sh
sudo ./scripts/jamf-uninstall.sh ignored ignored ignored false
```

The uninstaller stops active instances, unloads the LaunchAgent, removes the app and LaunchAgent, and forgets the installer receipt.

## Notifications

Users are asked for notification permission on first launch. In managed environments, allow notifications for bundle ID `com.company.pomodorobar` using the applicable macOS Notifications configuration profile. Focus must be turned off during breaks if users should see other applications’ notifications.

## Troubleshooting

### The application does not build

Confirm that the Swift compiler and SDK come from the same Command Line Tools or Xcode installation:

```sh
xcode-select -p
swift --version
xcrun --show-sdk-path
```

If the compiler reports that the SDK is unsupported, update Xcode/Command Line Tools or select the matching Xcode installation with `xcode-select`.

### Focus does not change

- Open the Pomodoro Bar popover and read the Focus status shown below the timer controls. Shortcut errors are displayed there instead of being silently ignored.
- Select **Open Shortcuts** and confirm both required Shortcuts exist.
- Run both Shortcuts manually once and approve any prompts.
- Confirm their names exactly match the configured defaults.
- Test with `shortcuts run "Pomodoro Focus On"` in Terminal as the affected user.
- Confirm that the JAMF script did not run the app as root; Shortcuts belong to the signed-in user.

### Notifications do not appear

Check **System Settings → Notifications → Pomodoro Bar** and ensure notifications and sounds are enabled. Also check the active Focus configuration and your organization’s notification profile.

### The app does not start at login

Confirm `/Library/LaunchAgents/com.company.pomodorobar.plist` exists and validate it with:

```sh
plutil -lint /Library/LaunchAgents/com.company.pomodorobar.plist
```

LaunchAgents start only inside a user login session, not at the FileVault login screen.

## Security and privacy

- No telemetry, analytics, or network communication is implemented in the app.
- Preferences remain in the user’s Library and are preserved by default during uninstall.
- The deployment script accepts only HTTPS package URLs and can enforce the expected signing Team ID.
- Production packages should be signed, verified, and distributed through an authenticated management system.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the development workflow and pull-request checklist.

## Security

See [SECURITY.md](SECURITY.md) for supported versions and private vulnerability reporting guidance.

## License

No license has been selected yet. Add your organization’s approved license before publishing or accepting external contributions.
