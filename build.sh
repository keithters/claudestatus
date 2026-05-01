#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v xcodegen >/dev/null 2>&1; then
    echo "× xcodegen not found. Install with:  brew install xcodegen"
    exit 1
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
    echo "× xcodebuild not found. You need full Xcode (App Store)."
    echo "  After installing Xcode:"
    echo "    sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
    echo "    sudo xcodebuild -license accept"
    exit 1
fi

echo "→ Generating Xcode project..."
xcodegen generate

echo "→ Building Release..."
xcodebuild \
    -project ClaudeStatus.xcodeproj \
    -scheme ClaudeStatus \
    -configuration Release \
    -derivedDataPath build \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY="-" \
    DEVELOPMENT_TEAM="" \
    -quiet

APP="build/Build/Products/Release/ClaudeStatus.app"
if [ ! -d "$APP" ]; then
    echo "× Build succeeded but couldn't locate $APP"
    exit 1
fi

echo "✓ Built $APP"
echo
echo "Next steps:"
echo "  1. Move into Applications:"
echo "       cp -R \"$APP\" /Applications/"
echo "  2. Open it once so the system registers the widget extension:"
echo "       open /Applications/ClaudeStatus.app"
echo "  3. Right-click your desktop → Edit Widgets → search “Claude”"
echo "       (or open Notification Center and use Edit Widgets there)"
