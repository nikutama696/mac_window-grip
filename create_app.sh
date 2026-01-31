#!/bin/bash
set -e

APP_NAME="WindowGrip"
BUILD_PATH=".build/release/$APP_NAME"
APP_BUNDLE="$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "Started creating $APP_NAME.app..."

# 1. Build Release
echo "Building release version..."
swift build -c release

# 2. Create Directory Structure
echo "Creating App Bundle structure..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# 3. Copy Binary
echo "Copying binary..."
if [ ! -f "$BUILD_PATH" ]; then
    echo "Error: Build failed or binary not found at $BUILD_PATH"
    exit 1
fi
cp "$BUILD_PATH" "$MACOS_DIR/"

# 4. Copy and Update Info.plist
echo "Configuring Info.plist..."
SOURCE_PLIST="WindowGrip/WindowGrip/App/Info.plist"
DEST_PLIST="$CONTENTS_DIR/Info.plist"

cp "$SOURCE_PLIST" "$DEST_PLIST"

# Replace variables
sed -i '' "s/\$(EXECUTABLE_NAME)/$APP_NAME/g" "$DEST_PLIST"
sed -i '' "s/\$(PRODUCT_NAME)/$APP_NAME/g" "$DEST_PLIST"
sed -i '' "s/\$(PRODUCT_BUNDLE_PACKAGE_TYPE)/APPL/g" "$DEST_PLIST"
sed -i '' "s/\$(DEVELOPMENT_LANGUAGE)/en/g" "$DEST_PLIST"

# 5. Code Signing (Ad-hoc)
echo "Signing app bundle..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo ""
echo "✅ $APP_BUNDLE created successfully!"
echo "You can move this to your Applications folder or Desktop."
