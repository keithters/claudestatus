import SwiftUI
import AppKit

@main
struct ClaudeStatusApp: App {
    private static let launchTime = Date()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    NSWorkspace.shared.open(url)
                    // If we were spawned specifically to handle this URL (widget tap),
                    // exit instead of showing our first-launch window.
                    if Date().timeIntervalSince(Self.launchTime) < 1.5 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            NSApp.terminate(nil)
                        }
                    }
                }
        }
        .windowResizability(.contentSize)
    }
}

struct ContentView: View {
    @State private var bundle: StatusBundle?

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Palette.indicator(bundle?.summary?.status.indicator ?? "none").opacity(0.20))
                    .frame(width: 88, height: 88)
                Circle()
                    .fill(Palette.indicator(bundle?.summary?.status.indicator ?? "none"))
                    .frame(width: 36, height: 36)
            }
            VStack(spacing: 3) {
                Text("Claude Status Widget")
                    .font(.title2.bold())
                Text(bundle?.summary?.status.description ?? "Loading…")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Divider().padding(.horizontal, 32)
            VStack(alignment: .leading, spacing: 9) {
                step("1.", "Right-click your desktop")
                step("2.", "Choose “Edit Widgets”")
                step("3.", "Search “Claude” and drag to your desktop")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 36)
            Button {
                if let url = URL(string: "https://status.claude.com") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                Text("Open status.claude.com")
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 28)
        .padding(.horizontal, 16)
        .frame(width: 420)
        .task {
            bundle = await StatusFetcher.shared.fetchAll()
        }
    }

    @ViewBuilder
    private func step(_ num: String, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(num)
                .foregroundStyle(.secondary)
                .frame(width: 18, alignment: .trailing)
                .font(.callout.weight(.semibold))
                .monospacedDigit()
            Text(text)
                .font(.callout)
        }
    }
}
