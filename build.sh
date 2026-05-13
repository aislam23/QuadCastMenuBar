#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="QuadCastMenuBar"
BUILD_DIR="$SCRIPT_DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS/MacOS"
ARCH=$(uname -m)

echo "Building QuadCast RGB for $ARCH..."

rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR"

swiftc \
    -parse-as-library \
    -target "${ARCH}-apple-macos14.0" \
    -framework SwiftUI \
    -framework IOKit \
    -framework ServiceManagement \
    -O \
    "$SCRIPT_DIR"/Sources/*.swift \
    -o "$MACOS_DIR/$APP_NAME"

mkdir -p "$CONTENTS/Resources"
cp "$SCRIPT_DIR/Resources/Info.plist" "$CONTENTS/"
cp "$SCRIPT_DIR/Resources/AppIcon.icns" "$CONTENTS/Resources/"

echo "Build successful: $APP_BUNDLE"
echo ""
echo "To install:  cp -r '$APP_BUNDLE' /Applications/"
echo "To run:      open '$APP_BUNDLE'"
