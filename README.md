# Claude Status Widget

A macOS desktop widget that shows live status from [status.claude.com](https://status.claude.com): component health, recent incidents (with duration), and a 24-hour severity ring on the header dot when something major happened recently.

![Claude Status Widget](screenshot.png)

## Install (no building required)

> **Heads up:** This app isn't signed by an Apple Developer ID, so macOS will block it on first launch. The steps below include the bypass.

### Download & install

1. Download **[ClaudeStatus.app.zip](https://github.com/keithters/claudestatus/releases/latest/download/ClaudeStatus.app.zip)** from the latest release.
2. Double-click the zip in your Downloads folder to unpack it.
3. Drag `ClaudeStatus.app` into your **Applications** folder.
4. Open it the first time:
   - Double-click `ClaudeStatus.app` — macOS will refuse and show a warning. Click **Done**.
   - Open **System Settings → Privacy & Security**, scroll to "Security", and click **Open Anyway** next to the `ClaudeStatus` message.
   - In the confirmation dialog, click **Open**.
5. A small confirmation window appears — you can close it.
6. **Right-click your desktop → Edit Widgets**, search "Claude", and drag a size onto the desktop.

### Or, one line in Terminal

```sh
curl -L https://github.com/keithters/claudestatus/releases/latest/download/ClaudeStatus.app.zip -o /tmp/cs.zip && \
ditto -x -k /tmp/cs.zip /Applications/ && \
xattr -dr com.apple.quarantine /Applications/ClaudeStatus.app && \
open /Applications/ClaudeStatus.app
```

Then right-click your desktop → Edit Widgets and add the widget.

## Build from source

Requires full Xcode and [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```sh
brew install xcodegen
./build.sh
cp -R build/Build/Products/Release/ClaudeStatus.app /Applications/
open /Applications/ClaudeStatus.app
```

## Layout

- `App/` — containing macOS app (first-launch view)
- `WidgetExt/` — WidgetKit extension (small / medium / large views)
- `Shared/` — models, palette, async fetcher
- `Project.yml` — XcodeGen spec; `.xcodeproj` is regenerated from this
