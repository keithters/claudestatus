#!/usr/bin/env bash
#
# Build, sign with Developer ID, notarize with Apple, staple, zip.
# Outputs a Gatekeeper-friendly artifact at /tmp/ClaudeStatus.app.zip.
#
# One-time setup (do these once):
#
#   1. Install your Developer ID Application certificate:
#        Xcode → Settings → Accounts → (sign in) → Manage Certificates
#        → + → "Developer ID Application"
#
#   2. Generate an app-specific password at:
#        https://appleid.apple.com → Sign-In and Security
#        → App-Specific Passwords → "+"
#        (label it "claudestatus-notary"; copy the value once)
#
#   3. Find your Team ID:
#        https://developer.apple.com/account → Membership Details
#        (10-char alphanumeric, e.g. ABCD123456)
#
#   4. Store the notarization credentials in your keychain (one time):
#        xcrun notarytool store-credentials "claude-status-notary" \
#            --apple-id "your.apple.id@email.com" \
#            --team-id "ABCD123456" \
#            --password "xxxx-xxxx-xxxx-xxxx"
#
# Per-release:
#   TEAM_ID=ABCD123456 ./release.sh
#
set -euo pipefail
cd "$(dirname "$0")"

: "${TEAM_ID:?Set TEAM_ID (your 10-char Apple Developer Team ID — see header for help)}"
: "${NOTARY_PROFILE:=claude-status-notary}"
: "${VERSION:=$(date +%Y.%m.%d)}"
: "${IDENTITY:=Developer ID Application}"

# --- Preflight ---------------------------------------------------------------

if ! command -v xcodegen >/dev/null 2>&1; then
    echo "× xcodegen not found.  brew install xcodegen"; exit 1
fi
if ! command -v xcodebuild >/dev/null 2>&1; then
    echo "× full Xcode required (Command Line Tools alone won't build .appex)"; exit 1
fi

if ! security find-identity -v -p codesigning 2>/dev/null | grep -q "$IDENTITY"; then
    cat <<EOM
× No "$IDENTITY" identity found in your keychain.
  Open Xcode → Settings → Accounts → Manage Certificates → + → "Developer ID Application"
  (or generate one at https://developer.apple.com/account/resources/certificates)
EOM
    exit 1
fi

if ! xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" >/dev/null 2>&1; then
    cat <<EOM
× Notary keychain profile "$NOTARY_PROFILE" not found. Run once:

    xcrun notarytool store-credentials "$NOTARY_PROFILE" \\
        --apple-id "YOUR_APPLE_ID@email.com" \\
        --team-id  "$TEAM_ID" \\
        --password "xxxx-xxxx-xxxx-xxxx"

  The password is an *app-specific* password from https://appleid.apple.com
  (Sign-In and Security → App-Specific Passwords).
EOM
    exit 1
fi

echo "→ TEAM_ID=$TEAM_ID  PROFILE=$NOTARY_PROFILE  VERSION=$VERSION"

# --- Build -------------------------------------------------------------------

echo "→ Generating Xcode project..."
xcodegen generate >/dev/null

echo "→ Building Release with Developer ID signing..."
rm -rf build
xcodebuild \
    -project ClaudeStatus.xcodeproj \
    -scheme ClaudeStatus \
    -configuration Release \
    -derivedDataPath build \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY="$IDENTITY" \
    CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
    OTHER_CODE_SIGN_FLAGS="--timestamp --options runtime" \
    -quiet

APP="build/Build/Products/Release/ClaudeStatus.app"
[ -d "$APP" ] || { echo "× build did not produce $APP"; exit 1; }

# --- Verify signature --------------------------------------------------------

echo "→ Verifying signature..."
codesign --verify --deep --strict --verbose=2 "$APP" 2>&1 | tail -5

# --- Notarize ----------------------------------------------------------------

ZIP="/tmp/ClaudeStatus.app.zip"
echo "→ Zipping for notarization → $ZIP"
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"

echo "→ Submitting to Apple notary service (a few minutes; will block until done)..."
xcrun notarytool submit "$ZIP" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait

echo "→ Stapling notarization ticket..."
xcrun stapler staple "$APP"
xcrun stapler validate "$APP"

echo "→ Re-zipping the stapled app..."
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"

echo
echo "✓ Notarized release artifact: $ZIP"
echo
echo "Publish to GitHub:"
echo "  gh release create v$VERSION \"$ZIP\" --title \"v$VERSION\" --notes 'Notarized release.'"
