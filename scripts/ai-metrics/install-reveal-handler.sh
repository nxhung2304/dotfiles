#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_PATH="$HOME/Applications/AIRevealInFinder.app"
PLIST="$APP_PATH/Contents/Info.plist"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

mkdir -p "$HOME/Applications"
rm -rf "$APP_PATH"
osacompile -o "$APP_PATH" "$SCRIPT_DIR/reveal-in-finder.applescript"

/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier local.ai-metrics.reveal" "$PLIST" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string local.ai-metrics.reveal" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :LSUIElement bool true" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes array" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0 dict" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLName string AI metrics reveal" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes array" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string ai-reveal" "$PLIST"

codesign --force --deep --sign - "$APP_PATH"
"$LSREGISTER" -f "$APP_PATH"
