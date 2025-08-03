#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

APP_NAME="PowerOnGadget"
EXECUTABLE_NAME="poweron_gadget"

echo "Building in release configuration..."
swift build -c release

echo "Creating application bundle..."
mkdir -p "${APP_NAME}.app/Contents/MacOS"
mkdir -p "${APP_NAME}.app/Contents/Resources"

mv ".build/release/${EXECUTABLE_NAME}" "${APP_NAME}.app/Contents/MacOS/"
cp -R "Sources/${EXECUTABLE_NAME}/Resources" "${APP_NAME}.app/Contents/"
cp "Sources/${EXECUTABLE_NAME}/Info.plist" "${APP_NAME}.app/Contents/"

# Copy the icon if it exists
if [ -f "Sources/${EXECUTABLE_NAME}/Resources/AppIcon.icns" ]; then
    cp "Sources/${EXECUTABLE_NAME}/Resources/AppIcon.icns" "${APP_NAME}.app/Contents/Resources/"
fi

echo "Creating DMG file..."
hdiutil create -volname "${APP_NAME}" -srcfolder "${APP_NAME}.app" -ov -format UDZO "${APP_NAME}.dmg"

echo "Build and DMG creation complete!"
