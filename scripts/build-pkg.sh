#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
VERSION="${VERSION:-1.0.0}"
PKGROOT="$ROOT/.build/pkgroot"

"$ROOT/scripts/build-app.sh"
/bin/rm -rf "$PKGROOT"
/bin/mkdir -p "$PKGROOT/Applications"
/bin/cp -R "$ROOT/dist/Pomodoro Bar.app" "$PKGROOT/Applications/"
/bin/mkdir -p "$PKGROOT/Library/LaunchAgents"
/bin/cp "$ROOT/Resources/com.company.pomodorobar.plist" "$PKGROOT/Library/LaunchAgents/"
/usr/bin/pkgbuild --root "$PKGROOT" --scripts "$ROOT/scripts/pkg-scripts" --identifier com.company.pomodorobar.pkg --version "$VERSION" --install-location / "$ROOT/dist/PomodoroBar-$VERSION.pkg"
echo "Package: $ROOT/dist/PomodoroBar-$VERSION.pkg"
