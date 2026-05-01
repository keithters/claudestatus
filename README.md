# Claude Status Widget

A macOS desktop widget that shows live status from [status.claude.com](https://status.claude.com): component health, recent incidents (with duration), and a 24-hour severity ring on the header dot when something major happened recently.

![Claude Status Widget](screenshot.png)

## Build

Requires full Xcode and [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```sh
brew install xcodegen
./build.sh
```

Then:

1. `cp -R build/Build/Products/Release/ClaudeStatus.app /Applications/`
2. `open /Applications/ClaudeStatus.app` (registers the widget extension)
3. Right-click the desktop → **Edit Widgets** → search "Claude"

## Layout

- `App/` — containing macOS app (first-launch view)
- `WidgetExt/` — WidgetKit extension (small / medium / large)
- `Shared/` — models, palette, async fetcher
- `Project.yml` — XcodeGen spec; `.xcodeproj` is regenerated from this
