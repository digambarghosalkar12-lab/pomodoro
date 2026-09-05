# Changelog

All notable project changes are documented here.

## 1.0.0 - Unreleased

### Added

- Native macOS menu-bar Pomodoro timer.
- Standard focus, short-break, and fourth-session long-break cycle.
- Animated progress ring, completion count, sounds, and notifications.
- Background Focus/DND integration through Apple Shortcuts.
- Guided Shortcut setup and visible automation errors.
- LaunchAgent and package post-install startup support.
- JAMF installation, managed-duration, and uninstall scripts.
- macOS app icon and GitHub project documentation.

### Fixed

- Skipped focus sessions no longer increment the completed-session count.
- Focus Shortcut commands execute serially to prevent rapid Start/Pause races.
