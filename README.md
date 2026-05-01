# Claude Status Widget

A macOS desktop widget that shows live status from [status.claude.com](https://status.claude.com): component health, recent incidents (with duration), and a 24-hour severity ring on the header dot when something major happened recently.

![Claude Status Widget](screenshot.png)

## Install

The app is signed with an Apple Developer ID and notarized by Apple, so macOS accepts it without security warnings.

1. Download **[ClaudeStatus.app.zip](https://github.com/keithters/claudestatus/releases/latest/download/ClaudeStatus.app.zip)**.
2. Unzip and drag `ClaudeStatus.app` into your **Applications** folder.
3. Open it once (a small confirmation window appears — you can close it).
4. **Right-click your desktop → Edit Widgets**, search "Claude", and drag a size onto the desktop.

Or, one line in Terminal:

```sh
curl -L https://github.com/keithters/claudestatus/releases/latest/download/ClaudeStatus.app.zip -o /tmp/cs.zip && \
ditto -x -k /tmp/cs.zip /Applications/ && \
open /Applications/ClaudeStatus.app
```

## Build from source

Requires full Xcode and [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```sh
brew install xcodegen
./build.sh
cp -R build/Build/Products/Release/ClaudeStatus.app /Applications/
open /Applications/ClaudeStatus.app
```

## Releasing (maintainer)

`./release.sh` builds with a Developer ID signature, submits to Apple's notary service, staples the ticket, and re-zips the result. The script does preflight checks and prints what's missing if setup is incomplete.

One-time setup:

1. Install a **Developer ID Application** certificate (Xcode → Settings → Accounts → Manage Certificates → + → "Developer ID Application").
2. Generate an app-specific password at [appleid.apple.com](https://appleid.apple.com) → Sign-In and Security → App-Specific Passwords.
3. Store the notarization credentials in your keychain:

   ```sh
   xcrun notarytool store-credentials "claude-status-notary" \
       --apple-id "you@example.com" \
       --team-id "ABCD123456" \
       --password "xxxx-xxxx-xxxx-xxxx"
   ```

Per release:

```sh
TEAM_ID=ABCD123456 VERSION=1.0.1 ./release.sh
gh release create v1.0.1 /tmp/ClaudeStatus.app.zip --title v1.0.1 --notes "Notarized release."
```

## Layout

- `App/` — containing macOS app (first-launch view)
- `WidgetExt/` — WidgetKit extension (small / medium / large views)
- `Shared/` — models, palette, async fetcher
- `Project.yml` — XcodeGen spec; `.xcodeproj` is regenerated from this
