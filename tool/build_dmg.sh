#!/usr/bin/env bash
set -euo pipefail

APP_NAME="toney.app"
VOL_NAME="Toney Music"
APP_PATH="build/macos/Build/Products/Release/${APP_NAME}"
ARROW_SRC="assets/images/drag to.png"
ARROW_NAME="drag to.png"

STAGING_DIR="build/dmg-staging"
DMG_RW="build/toney-music-rw.dmg"
VERSION="$(awk -F': *' '/^version:/ {print $2; exit}' pubspec.yaml)"
if [[ -z "${VERSION:-}" ]]; then
  echo "Missing version in pubspec.yaml."
  exit 1
fi
DMG_OUT="build/toney-music-${VERSION}.dmg"
device=""

cleanup() {
  if [[ -n "$device" ]]; then
    hdiutil detach "$device" >/dev/null 2>&1 || true
  fi
}

trap cleanup EXIT

if [[ ! -d "$APP_PATH" ]]; then
  echo "Missing ${APP_PATH}. Run 'flutter build macos --release' first."
  exit 1
fi

if [[ ! -f "$ARROW_SRC" ]]; then
  echo "Missing ${ARROW_SRC}."
  exit 1
fi

rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/"
cp "$ARROW_SRC" "$STAGING_DIR/$ARROW_NAME"
ln -sf /Applications "$STAGING_DIR/Applications"

setfile_bin=""
if command -v SetFile >/dev/null 2>&1; then
  setfile_bin="$(command -v SetFile)"
elif [[ -x "/Applications/Xcode.app/Contents/Developer/Tools/SetFile" ]]; then
  setfile_bin="/Applications/Xcode.app/Contents/Developer/Tools/SetFile"
fi

if [[ -n "$setfile_bin" ]]; then
  "$setfile_bin" -a E "$STAGING_DIR/$ARROW_NAME"
fi

rm -f "$DMG_RW" "$DMG_OUT"
existing_device=$(hdiutil info | awk -v vol="/Volumes/$VOL_NAME" '$0 ~ vol {print $1; exit}')
if [[ -n "${existing_device:-}" ]]; then
  hdiutil detach "$existing_device"
fi
hdiutil create \
  -srcfolder "$STAGING_DIR" \
  -volname "$VOL_NAME" \
  -format UDRW \
  -ov \
  "$DMG_RW"

attach_output=$(hdiutil attach -readwrite -noverify -noautoopen "$DMG_RW")
device=$(echo "$attach_output" | awk '/\/Volumes/ {print $1; exit}')
mount=$(echo "$attach_output" | awk '/\/Volumes/ {print $3; exit}')

osascript <<EOF
tell application "Finder"
  tell disk "$VOL_NAME"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {120, 120, 860, 500}
    set theViewOptions to the icon view options of container window
    set arrangement of theViewOptions to not arranged
    set icon size of theViewOptions to 128
    set label position of theViewOptions to bottom
    set position of item "$APP_NAME" to {150, 200}
    set position of item "$ARROW_NAME" to {360, 200}
    set position of item "Applications" to {570, 200}
    update without registering applications
    delay 1
    close
  end tell
end tell
EOF

hdiutil detach "$device"
device=""
hdiutil convert "$DMG_RW" -format UDZO -imagekey zlib-level=9 -ov -o "$DMG_OUT"
rm -f "$DMG_RW"
