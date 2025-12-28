#!/bin/bash

# Script to add Info.plist files to Google frameworks that don't have them

FRAMEWORKS_DIR="${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}"

# Function to create Info.plist for a framework
create_info_plist() {
    local framework_name=$1
    local framework_path="${FRAMEWORKS_DIR}/${framework_name}.framework"
    local info_plist="${framework_path}/Info.plist"
    
    if [ -d "$framework_path" ] && [ ! -f "$info_plist" ]; then
        echo "Creating Info.plist for ${framework_name}"
        cat > "$info_plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${framework_name}</string>
    <key>CFBundleIdentifier</key>
    <string>com.google.${framework_name}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${framework_name}</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>MinimumOSVersion</key>
    <string>12.0</string>
</dict>
</plist>
PLIST
    fi
}

# Create Info.plist for frameworks that need it
create_info_plist "GoogleMobileAds"
create_info_plist "UserMessagingPlatform"

echo "Framework Info.plist fix completed"
