import WidgetKit
import SwiftUI

@main
struct ClaudeStatusBundle: WidgetBundle {
    var body: some Widget {
        ClaudeStatusWidget()
    }
}

struct ClaudeStatusWidget: Widget {
    let kind: String = "ClaudeStatusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StatusProvider()) { entry in
            EntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Claude Status")
        .description("Live status of Claude services and recent incidents.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct StatusEntry: TimelineEntry, Sendable {
    let date: Date
    let summary: StatusSummary?
    let incidents: [Incident]
    let error: Bool

    static let placeholder = StatusEntry(
        date: Date(),
        summary: nil,
        incidents: [],
        error: false
    )
}

struct StatusProvider: TimelineProvider {
    func placeholder(in context: Context) -> StatusEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (StatusEntry) -> Void) {
        Task {
            let b = await StatusFetcher.shared.fetchAll()
            completion(StatusEntry(date: b.fetchedAt, summary: b.summary, incidents: b.incidents, error: b.error))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StatusEntry>) -> Void) {
        Task {
            let b = await StatusFetcher.shared.fetchAll()
            let entry = StatusEntry(date: b.fetchedAt, summary: b.summary, incidents: b.incidents, error: b.error)
            // 5 min refresh; system may throttle further. Faster cadence if there's an active incident.
            let hasActive = b.incidents.contains { !$0.isResolved }
            let next = Date().addingTimeInterval(hasActive ? 60 : 300)
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }
}
