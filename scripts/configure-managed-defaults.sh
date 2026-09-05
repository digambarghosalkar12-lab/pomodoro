#!/bin/zsh
# Optional JAMF policy script. Runs as root and configures the current user.
set -euo pipefail

USER_NAME=$(/usr/bin/stat -f '%Su' /dev/console)
[[ "$USER_NAME" == "root" || "$USER_NAME" == "loginwindow" ]] && exit 0
USER_HOME=$(/usr/bin/dscl . -read "/Users/$USER_NAME" NFSHomeDirectory | /usr/bin/awk '{print $2}')
PLIST="$USER_HOME/Library/Preferences/com.company.pomodorobar.plist"
/usr/bin/touch "$PLIST"

/usr/libexec/PlistBuddy -c "Set :focusMinutes ${4:-25}" "$PLIST" 2>/dev/null || /usr/libexec/PlistBuddy -c "Add :focusMinutes integer ${4:-25}" "$PLIST"
/usr/libexec/PlistBuddy -c "Set :shortBreakMinutes ${5:-5}" "$PLIST" 2>/dev/null || /usr/libexec/PlistBuddy -c "Add :shortBreakMinutes integer ${5:-5}" "$PLIST"
/usr/libexec/PlistBuddy -c "Set :longBreakMinutes ${6:-15}" "$PLIST" 2>/dev/null || /usr/libexec/PlistBuddy -c "Add :longBreakMinutes integer ${6:-15}" "$PLIST"
/usr/sbin/chown "$USER_NAME":staff "$PLIST"
/usr/bin/killall cfprefsd 2>/dev/null || true
