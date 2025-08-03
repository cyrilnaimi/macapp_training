#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

APP_NAME="PowerOnGadget"
EXECUTABLE_NAME="poweron_gadget"
HELPER_NAME="PowerOnHelper"
BUNDLE_ID="com.naimicyril.poweron"
HELPER_ID="com.naimicyril.poweron.helper"

# Code signing identity - set to "-" for ad-hoc signing or your Developer ID
SIGNING_IDENTITY="-"

echo "Building in release configuration..."
swift build -c release

echo "Creating application bundle..."
mkdir -p "${APP_NAME}.app/Contents/MacOS"
mkdir -p "${APP_NAME}.app/Contents/Resources"
mkdir -p "${APP_NAME}.app/Contents/Library/LaunchServices"

# Copy main executable
cp ".build/release/${EXECUTABLE_NAME}" "${APP_NAME}.app/Contents/MacOS/"

# Copy resources
cp -R "Sources/${EXECUTABLE_NAME}/Resources/"* "${APP_NAME}.app/Contents/Resources/"
cp "Sources/${EXECUTABLE_NAME}/Info.plist" "${APP_NAME}.app/Contents/"

# Copy the icon if it exists
if [ -f "Sources/${EXECUTABLE_NAME}/Resources/AppIcon.icns" ]; then
    cp "Sources/${EXECUTABLE_NAME}/Resources/AppIcon.icns" "${APP_NAME}.app/Contents/Resources/"
fi

# Copy helper tool
echo "Copying helper tool..."
cp ".build/release/${HELPER_NAME}" "${APP_NAME}.app/Contents/Library/LaunchServices/"

# Copy helper Info.plist and launchd plist
cp "Sources/${HELPER_NAME}/Info.plist" "${APP_NAME}.app/Contents/Library/LaunchServices/${HELPER_ID}-Info.plist"
cp "Sources/${HELPER_NAME}/${HELPER_ID}.plist" "${APP_NAME}.app/Contents/Library/LaunchServices/${HELPER_ID}.plist"

# Code sign the helper tool
echo "Code signing helper tool..."
codesign --force --sign "${SIGNING_IDENTITY}" \
    --identifier "${HELPER_ID}" \
    --options runtime \
    "${APP_NAME}.app/Contents/Library/LaunchServices/${HELPER_NAME}"

# Code sign the main app with entitlements
echo "Code signing main application..."
codesign --force --sign "${SIGNING_IDENTITY}" \
    --entitlements "Sources/${EXECUTABLE_NAME}/PowerOnGadget.entitlements" \
    --options runtime \
    --deep \
    "${APP_NAME}.app"

# Verify code signing
echo "Verifying code signing..."
codesign --verify --verbose "${APP_NAME}.app"
codesign --verify --verbose "${APP_NAME}.app/Contents/Library/LaunchServices/${HELPER_NAME}"

# Create SMJobBless requirements
echo "Setting up SMJobBless requirements..."
# The helper tool needs to know which apps can install it
/usr/libexec/PlistBuddy -c "Add :SMAuthorizedClients:0 string 'identifier \"${BUNDLE_ID}\" and anchor apple generic and certificate leaf[subject.CN] = \"${SIGNING_IDENTITY}\"'" \
    "${APP_NAME}.app/Contents/Library/LaunchServices/${HELPER_ID}-Info.plist" 2>/dev/null || true

# The app needs to know the requirements of the helper tool
/usr/libexec/PlistBuddy -c "Add :SMPrivilegedExecutables dict" "${APP_NAME}.app/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :SMPrivilegedExecutables:${HELPER_ID} string 'identifier \"${HELPER_ID}\" and anchor apple generic and certificate leaf[subject.CN] = \"${SIGNING_IDENTITY}\"'" \
    "${APP_NAME}.app/Contents/Info.plist" 2>/dev/null || true

echo "Creating DMG file..."
# Create a temporary directory for DMG contents
DMG_TEMP="dmg_temp"
rm -rf "${DMG_TEMP}"
mkdir -p "${DMG_TEMP}"

# Copy app to DMG directory
cp -R "${APP_NAME}.app" "${DMG_TEMP}/"

# Create a symbolic link to /Applications
ln -s /Applications "${DMG_TEMP}/Applications"

# Create DMG
hdiutil create -volname "${APP_NAME}" -srcfolder "${DMG_TEMP}" -ov -format UDZO "${APP_NAME}.dmg"

# Clean up
rm -rf "${DMG_TEMP}"

echo "Build and DMG creation complete!"
echo ""
echo "IMPORTANT: For the helper tool to work properly:"
echo "1. The app must be signed with a valid Developer ID (not ad-hoc signing)"
echo "2. The app must be run from /Applications"
echo "3. The user will be prompted for administrator privileges on first run"
echo ""
echo "To install: "
echo "1. Mount ${APP_NAME}.dmg"
echo "2. Drag ${APP_NAME}.app to Applications"
echo "3. Run the app from Applications"