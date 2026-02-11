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

# 5. Copy Entitlements
echo "Copying entitlements..."
SOURCE_ENTITLEMENTS="WindowGrip/WindowGrip/App/WindowGrip.entitlements"
DEST_ENTITLEMENTS="$CONTENTS_DIR/WindowGrip.entitlements"
if [ -f "$SOURCE_ENTITLEMENTS" ]; then
    cp "$SOURCE_ENTITLEMENTS" "$DEST_ENTITLEMENTS"
fi

# 6. Code Signing with stable identifier
echo "Signing app bundle..."
# Use the bundle identifier for more stable signing
# This helps macOS recognize it as the same app across rebuilds
codesign --force --deep --sign - --identifier "com.example.WindowGrip" "$APP_BUNDLE"

echo ""
echo "✅ $APP_BUNDLE created successfully!"
echo "You can move this to your Applications folder or Desktop."
echo ""
echo "Note: If you've already granted permissions to a previous version,"
echo "you may need to remove the old app from System Settings > Privacy & Security > Accessibility"
echo "and re-add the new one."
