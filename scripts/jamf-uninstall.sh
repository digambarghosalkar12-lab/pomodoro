#!/bin/zsh
# JAMF Pro uninstall script for Pomodoro Bar.
# Parameter 4: "true" removes per-user preferences; default "false" preserves them.
set -euo pipefail

APP="/Applications/Pomodoro Bar.app"
LAUNCH_AGENT="/Library/LaunchAgents/com.company.pomodorobar.plist"
RECEIPT="com.company.pomodorobar.pkg"
REMOVE_USER_DATA="${4:-false}"

if [[ "$REMOVE_USER_DATA" != "true" && "$REMOVE_USER_DATA" != "false" ]]; then
  echo "ERROR: Parameter 4 must be true or false."
  exit 2
fi

# Stop the agent in every currently active GUI session before removing its plist.
while IFS= read -r USER_ID; do
  [[ -z "$USER_ID" ]] && continue
  /bin/launchctl bootout "gui/$USER_ID" "$LAUNCH_AGENT" 2>/dev/null || true
done < <(/usr/bin/who | /usr/bin/awk '$2 == "console" {print $1}' | /usr/bin/sort -u | while IFS= read -r USER_NAME; do /usr/bin/id -u "$USER_NAME"; done)

# Stop any remaining copy started manually or by an older policy.
while IFS= read -r PROCESS_ID; do
  [[ -n "$PROCESS_ID" ]] && /bin/kill "$PROCESS_ID" 2>/dev/null || true
done < <(/usr/bin/pgrep -f '^/Applications/Pomodoro Bar.app/Contents/MacOS/PomodoroBar$' || true)

[[ -d "$APP" ]] && /bin/rm -rf "$APP"
[[ -f "$LAUNCH_AGENT" ]] && /bin/rm -f "$LAUNCH_AGENT"
/usr/sbin/pkgutil --forget "$RECEIPT" >/dev/null 2>&1 || true

if [[ "$REMOVE_USER_DATA" == "true" ]]; then
  while IFS= read -r RECORD; do
    USER_NAME="${RECORD%% *}"
    USER_ID="${RECORD##* }"
    (( USER_ID < 500 )) && continue
    USER_HOME=$(/usr/bin/dscl . -read "/Users/$USER_NAME" NFSHomeDirectory 2>/dev/null | /usr/bin/awk '{print $2}')
    [[ -z "$USER_HOME" || ! -d "$USER_HOME/Library/Preferences" ]] && continue
    PREFS="$USER_HOME/Library/Preferences/com.company.pomodorobar.plist"
    [[ -f "$PREFS" ]] && /bin/rm -f "$PREFS"
  done < <(/usr/bin/dscl . -list /Users UniqueID)
  /usr/bin/killall cfprefsd 2>/dev/null || true
  echo "Pomodoro Bar and its per-user preferences were removed."
else
  echo "Pomodoro Bar was removed. Per-user preferences were preserved."
fi
