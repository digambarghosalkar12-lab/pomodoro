#!/bin/zsh
# JAMF Pro script. Set Parameter 4 to an HTTPS URL containing PomodoroBar.pkg.
set -euo pipefail

PKG_URL="${4:-}"
EXPECTED_TEAM_ID="${5:-}"
TMP_PKG="/private/tmp/PomodoroBar.pkg"
APP="/Applications/Pomodoro Bar.app"

if [[ -z "$PKG_URL" || "$PKG_URL" != https://* ]]; then
  echo "ERROR: JAMF parameter 4 must be the HTTPS package URL."
  exit 2
fi

/usr/bin/curl --fail --location --silent --show-error "$PKG_URL" --output "$TMP_PKG"
/usr/sbin/pkgutil --check-signature "$TMP_PKG"

if [[ -n "$EXPECTED_TEAM_ID" ]]; then
  ACTUAL_TEAM_ID=$(/usr/sbin/pkgutil --check-signature "$TMP_PKG" 2>&1 | /usr/bin/sed -n 's/.*Team Identifier: \([^)]*\).*/\1/p' | /usr/bin/head -1)
  if [[ "$ACTUAL_TEAM_ID" != "$EXPECTED_TEAM_ID" ]]; then
    echo "ERROR: Package Team ID mismatch."
    /bin/rm -f "$TMP_PKG"
    exit 3
  fi
fi

/usr/sbin/installer -pkg "$TMP_PKG" -target /
/bin/rm -f "$TMP_PKG"

CONSOLE_USER=$(/usr/bin/stat -f '%Su' /dev/console)
if [[ "$CONSOLE_USER" != "root" && "$CONSOLE_USER" != "loginwindow" && -d "$APP" ]]; then
  USER_ID=$(/usr/bin/id -u "$CONSOLE_USER")
  /bin/launchctl asuser "$USER_ID" /usr/bin/open -gja "$APP" || true
fi

echo "Pomodoro Bar installed successfully."
