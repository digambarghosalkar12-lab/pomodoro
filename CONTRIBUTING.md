# Contributing to Pomodoro Bar

Thank you for improving Pomodoro Bar.

## Development setup

1. Use macOS 13 or newer with matching Xcode Command Line Tools and SDK versions.
2. Clone the repository.
3. Run `./scripts/build-app.sh` without `sudo`.
4. Open `dist/Pomodoro Bar.app` and test the affected behavior.

The project intentionally avoids third-party runtime dependencies. Discuss a new dependency before adding it.

## Before opening a pull request

- Build the release configuration successfully.
- Run `zsh -n scripts/*.sh scripts/pkg-scripts/postinstall`.
- Run `plutil -lint Resources/*.plist`.
- Confirm `git diff --check` reports no errors.
- Test Start, Pause, Reset, Skip, short breaks, and the fourth-session long break.
- Confirm skipped sessions do not increment the completion count.
- Test both Focus Shortcuts and their error messages.
- Test notifications and completion sounds.
- Test package installation, login launch, upgrade, and uninstall behavior when those areas change.
- Update the README, deployment guide, and changelog when behavior changes.

## Issues

Include the macOS version, Mac architecture, application version, deployment method, reproduction steps, expected result, and actual result. Remove organization names, package URLs, signing details, and other sensitive information from logs.

## Pull requests

Keep each pull request focused. Explain the user-visible change, testing performed, and JAMF or backward-compatibility impact. Do not commit `.build`, `dist`, packages, signing certificates, provisioning material, or user preference files.
