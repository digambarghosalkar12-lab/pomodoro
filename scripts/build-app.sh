#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
APP_NAME="Pomodoro Bar"
DIST_DIR="${DIST_DIR:-$ROOT/dist}"
APP="$DIST_DIR/$APP_NAME.app"
BUILD="${BUILD_DIR:-$ROOT/.build}"
IDENTITY="${CODE_SIGN_IDENTITY:--}"

cd "$ROOT"
env SWIFTPM_MODULECACHE_OVERRIDE="$BUILD/module-cache" CLANG_MODULE_CACHE_PATH="$BUILD/module-cache" swift build -c release --scratch-path "$BUILD"

/bin/mkdir -p "$DIST_DIR"
/bin/rm -rf "$APP"
/bin/mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
/bin/cp "$BUILD/release/PomodoroBar" "$APP/Contents/MacOS/PomodoroBar"
/bin/cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"
/bin/cp "$ROOT/Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
/bin/cp -R "$ROOT/Resources/Sounds" "$APP/Contents/Resources/Sounds"
/bin/cp -R "$ROOT/Resources/Shortcuts" "$APP/Contents/Resources/Shortcuts"
/usr/bin/codesign --force --deep --options runtime --sign "$IDENTITY" "$APP"

echo "Built: $APP"
