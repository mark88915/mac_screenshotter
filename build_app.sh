#!/bin/bash
# Build and package Screenshotter as a macOS .app bundle

set -e

APP_NAME="Screenshotter"
BUILD_DIR=".build/release"
APP_DIR="$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"

echo "Building release..."
swift build -c release

echo "Creating app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"

# Copy binary
cp "$BUILD_DIR/$APP_NAME" "$MACOS_DIR/"

# Copy Info.plist
cp Resources/Info.plist "$CONTENTS_DIR/"

# Ad-hoc code sign so macOS can persistently track permissions
echo "Code signing..."
codesign --force --sign - --deep "$APP_DIR"

echo "Done! App bundle created at: $APP_DIR"
echo ""
echo "To run: open $APP_DIR"
echo ""
echo "IMPORTANT: First run setup:"
echo "  1. Open the app, macOS will ask for Screen Recording permission"
echo "  2. Go to System Settings > Privacy & Security > Screen Recording"
echo "  3. Enable Screenshotter, then RESTART the app"
echo "  4. Also grant Accessibility permission if prompted"
