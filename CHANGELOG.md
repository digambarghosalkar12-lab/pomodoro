# Changelog

All notable project changes are documented here.

## 1.0.0 - Unreleased

### Added

- Native macOS menu-bar Pomodoro timer.
- Standard focus, short-break, and fourth-session long-break cycle.
- Animated progress ring, completion count, sounds, and notifications.
- Background Focus/DND integration through Apple Shortcuts.
- Guided Shortcut setup and visible automation errors.
- Hover-activated controls and four bundled phase chimes.
- LaunchAgent and package post-install startup support.
- JAMF installation, managed-duration, and uninstall scripts.
- macOS app icon and GitHub project documentation.
- Illustrated end-user and JAMF documentation for importing the bundled Focus Shortcuts.

### Fixed

- Skipped focus sessions no longer increment the completed-session count.
- Focus Shortcut commands execute serially to prevent rapid Start/Pause races.
- Shortcut setup hides automatically after both required Shortcuts are detected.
- Shortcut setup now opens the two bundled Apple-approved imports directly while preserving macOS user approval.
