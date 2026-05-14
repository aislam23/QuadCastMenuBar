#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="QuadCastMenuBar"
BUILD_DIR="$SCRIPT_DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS/MacOS"
ARCH=$(uname -m)
SIGN_IDENTITY="${SIGN_IDENTITY:-}"  # Set externally to use Developer ID signing

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
cp "$SCRIPT_DIR/Resources/quadcastrgb" "$CONTENTS/Resources/"

if [ -n "$SIGN_IDENTITY" ]; then
    echo "Signing with Developer ID: $SIGN_IDENTITY"
    # Sign nested binary first, then the outer bundle
    codesign --force --options runtime \
        --entitlements "$SCRIPT_DIR/Resources/entitlements.plist" \
        --sign "$SIGN_IDENTITY" \
        "$CONTENTS/Resources/quadcastrgb"
    codesign --force --deep --options runtime \
        --entitlements "$SCRIPT_DIR/Resources/entitlements.plist" \
        --sign "$SIGN_IDENTITY" \
        "$APP_BUNDLE"
else
    codesign --force --sign - "$CONTENTS/Resources/quadcastrgb"
    codesign --force --deep --sign - "$APP_BUNDLE"
fi

echo "Build successful: $APP_BUNDLE"
echo ""
echo "To install:  cp -r '$APP_BUNDLE' /Applications/"
echo "To run:      open '$APP_BUNDLE'"
