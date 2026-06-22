#!/bin/bash
#
# Ensures every embedded framework has an Info.plist carrying the keys the App
# Store upload validator requires: CFBundleShortVersionString, CFBundleVersion,
# and a non-empty MinimumOSVersion. SPM-distributed Google/Firebase frameworks
# ship either without an Info.plist (GoogleMobileAds, UserMessagingPlatform) or
# with those keys missing/empty (GoogleAppMeasurement, FirebaseAnalytics, ...),
# which makes `altool` reject the build at upload time.
#
# Wired in as the "Fix Google Frameworks Info.plist" run-script build phase,
# which runs AFTER "Embed Frameworks" — so any framework whose Info.plist we
# modify is re-signed to keep its code signature valid.

set -u

FRAMEWORKS_DIR="${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}"
PB="/usr/libexec/PlistBuddy"
MIN_OS="${IPHONEOS_DEPLOYMENT_TARGET:-12.0}"

if [ ! -d "$FRAMEWORKS_DIR" ]; then
    echo "No embedded frameworks at ${FRAMEWORKS_DIR}; nothing to fix."
    exit 0
fi

# Re-sign a bundle we modified, using the identity Xcode resolved for this build.
# Guarded so a Debug/ad-hoc build (identity "-") or missing identity is a no-op.
resign() {
    local path="$1"
    if [ -n "${EXPANDED_CODE_SIGN_IDENTITY:-}" ] && [ "${EXPANDED_CODE_SIGN_IDENTITY}" != "-" ]; then
        /usr/bin/codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY}" "$path" \
            && echo "  re-signed ${path##*/}"
    fi
}

for fw in "$FRAMEWORKS_DIR"/*.framework; do
    [ -d "$fw" ] || continue
    name="$(basename "$fw" .framework)"
    plist="${fw}/Info.plist"
    changed=0

    # Case 1: framework ships with no Info.plist at all — synthesize a minimal one.
    if [ ! -f "$plist" ]; then
        echo "Creating Info.plist for ${name}"
        cat > "$plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${name}</string>
    <key>CFBundleIdentifier</key>
    <string>com.google.${name}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${name}</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>MinimumOSVersion</key>
    <string>${MIN_OS}</string>
</dict>
</plist>
PLIST
        # The framework was code-signed during "Embed Frameworks" before this
        # plist existed, so its signature identifier is the bare binary name
        # while the new Info.plist declares a reverse-DNS bundle id. Re-sign so
        # the signature identifier matches CFBundleIdentifier (App Store requires
        # "Invalid Code Signature Identifier ... must match its Bundle Identifier").
        resign "$fw"
        continue
    fi

    # Case 2: Info.plist exists but is missing keys the validator requires.
    if ! "$PB" -c "Print :CFBundleShortVersionString" "$plist" >/dev/null 2>&1; then
        "$PB" -c "Add :CFBundleShortVersionString string 1.0" "$plist" \
            && { echo "  + CFBundleShortVersionString -> ${name}"; changed=1; }
    fi
    if ! "$PB" -c "Print :CFBundleVersion" "$plist" >/dev/null 2>&1; then
        "$PB" -c "Add :CFBundleVersion string 1" "$plist" && changed=1
    fi
    # MinimumOSVersion must exist AND be non-empty (Apple requires >= 8.0).
    if "$PB" -c "Print :MinimumOSVersion" "$plist" >/dev/null 2>&1; then
        current="$("$PB" -c "Print :MinimumOSVersion" "$plist" 2>/dev/null)"
        if [ -z "$current" ]; then
            "$PB" -c "Set :MinimumOSVersion ${MIN_OS}" "$plist" \
                && { echo "  ~ MinimumOSVersion (was empty) -> ${name}"; changed=1; }
        fi
    else
        "$PB" -c "Add :MinimumOSVersion string ${MIN_OS}" "$plist" \
            && { echo "  + MinimumOSVersion -> ${name}"; changed=1; }
    fi

    [ "$changed" -eq 1 ] && resign "$fw"
done

echo "Framework Info.plist fix completed"
