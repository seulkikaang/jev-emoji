#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/build/JEV Emoji.app"

cd "$ROOT_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
swiftc -parse-as-library -swift-version 5 -target arm64-apple-macosx13.0 \
    -framework AppKit \
    -framework ApplicationServices \
    -framework Carbon \
    -framework CoreGraphics \
    -framework Security \
    -framework SwiftUI \
    "$ROOT_DIR"/Sources/JEVEmoji/*.swift \
    -o "$APP_DIR/Contents/MacOS/JEVEmoji"
cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>JEVEmoji</string>
    <key>CFBundleIdentifier</key><string>com.jev.emoji</string>
    <key>CFBundleName</key><string>JEV Emoji</string>
    <key>CFBundleDisplayName</key><string>JEV Emoji</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0.0</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST
if [[ -n "${CODE_SIGN_IDENTITY:-}" ]]; then
    codesign --force --sign "$CODE_SIGN_IDENTITY" \
        --identifier com.jev.emoji --timestamp=none "$APP_DIR"
    codesign --verify --strict --verbose=2 "$APP_DIR"
fi
printf 'Built %s\n' "$APP_DIR"
