import WidgetKit
import SwiftUI

struct EntryView: View {
    let entry: StatusEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:  SmallView(entry: entry)
        case .systemMedium: MediumView(entry: entry)
        case .systemLarge:  LargeView(entry: entry)
        default:            MediumView(entry: entry)
        }
    }
}

private extension StatusEntry {
    var indicator: String { summary?.status.indicator ?? "none" }
    var statusDescription: String { summary?.status.description ?? "Loading…" }

    var visibleComponents: [Component] {
        guard let cs = summary?.components else { return [] }
        return cs
            .filter { !(($0.only_show_if_degraded ?? false) && $0.status == "operational") }
            .sorted { $0.position < $1.position }
    }

    var displayIncidents: [Incident] {
        let active   = incidents.filter { !$0.isResolved }
        let resolved = incidents.filter {  $0.isResolved }
        return active + resolved
    }
}

// MARK: - Small (155x155)

struct SmallView: View {
    let entry: StatusEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                statusDot(size: 12, halo: 22)
                Text("Claude")
                    .font(.system(size: 14, weight: .semibold))
                Spacer(minLength: 0)
            }
            Text(entry.statusDescription)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(2)
            Spacer(minLength: 0)
            if let r = recentSeverity(in: entry.incidents) {
                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(r.color)
                    Text("\(r.label) · \(r.timeAgo)")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            HStack {
                Spacer()
                Text(updatedString)
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var updatedString: String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: entry.date)
    }

    @ViewBuilder
    private func statusDot(size: CGFloat, halo: CGFloat) -> some View {
        ZStack {
            Circle().fill(Palette.indicator(entry.indicator).opacity(0.22)).frame(width: halo, height: halo)
            Circle().fill(Palette.indicator(entry.indicator)).frame(width: size, height: size)
        }
    }
}

// MARK: - Medium (320x155)

struct MediumView: View {
    let entry: StatusEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            header
            componentsList
            Spacer(minLength: 0)
            if let r = recentSeverity(in: entry.incidents) {
                HStack(spacing: 5) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(r.color)
                    Text("\(r.label) · \(r.timeAgo)")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            ZStack {
                if let r = recentSeverity(in: entry.incidents) {
                    Circle().stroke(r.color.opacity(0.85), lineWidth: 1.5).frame(width: 26, height: 26)
                }
                Circle().fill(Palette.indicator(entry.indicator).opacity(0.22)).frame(width: 22, height: 22)
                Circle().fill(Palette.indicator(entry.indicator)).frame(width: 10, height: 10)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("Claude")
                    .font(.system(size: 13, weight: .semibold))
                Text(entry.statusDescription)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
        }
    }

    private var componentsList: some View {
        VStack(spacing: 3) {
            ForEach(entry.visibleComponents.prefix(4)) { c in
                HStack(spacing: 6) {
                    Circle().fill(Palette.component(c.status)).frame(width: 6, height: 6)
                    Text(c.name)
                        .font(.system(size: 11))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Text(friendly(c.status))
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Palette.component(c.status))
                }
            }
        }
    }
}

// MARK: - Large (320x345)

struct LargeView: View {
    let entry: StatusEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            header
            divider
            componentsList
            if !displayIncidents.isEmpty {
                divider
                incidentsSection
            }
            Spacer(minLength: 0)
            footer
        }
    }

    private var displayIncidents: [Incident] {
        Array(entry.displayIncidents.prefix(3))
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                if let r = recentSeverity(in: entry.incidents) {
                    Circle().stroke(r.color.opacity(0.85), lineWidth: 1.5).frame(width: 30, height: 30)
                }
                Circle().fill(Palette.indicator(entry.indicator).opacity(0.22)).frame(width: 26, height: 26)
                Circle().fill(Palette.indicator(entry.indicator)).frame(width: 12, height: 12)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Claude")
                    .font(.system(size: 14, weight: .semibold))
                Text(statusText)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
    }

    private var statusText: String {
        if let r = recentSeverity(in: entry.incidents) {
            return "\(entry.statusDescription) · \(r.label) \(r.timeAgo)"
        }
        return entry.statusDescription
    }

    private var divider: some View {
        Rectangle().fill(.primary.opacity(0.08)).frame(height: 1)
    }

    private var componentsList: some View {
        VStack(spacing: 5) {
            ForEach(entry.visibleComponents) { c in
                HStack(spacing: 7) {
                    Circle().fill(Palette.component(c.status)).frame(width: 7, height: 7)
                    Text(c.name)
                        .font(.system(size: 11))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Text(friendly(c.status))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Palette.component(c.status))
                }
            }
        }
    }

    private var incidentsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(displayIncidents.contains(where: { !$0.isResolved }) ? "ACTIVE" : "RECENTLY RESOLVED")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.secondary)
                .kerning(0.5)
            ForEach(displayIncidents) { i in
                HStack(alignment: .top, spacing: 7) {
                    Circle()
                        .fill(Palette.indicator(i.impact ?? "minor"))
                        .frame(width: 6, height: 6)
                        .padding(.top, 4)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(i.name)
                            .font(.system(size: 11, weight: .medium))
                            .lineLimit(1)
                        Text(incidentMetaLine(i))
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }
                .opacity(i.isResolved ? 0.65 : 1.0)
            }
        }
    }

    private var footer: some View {
        HStack {
            Text("Updated \(updatedString)")
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
            Spacer()
            Link(destination: URL(string: "https://status.claude.com")!) {
                HStack(spacing: 3) {
                    Text("status.claude.com")
                        .font(.system(size: 9, weight: .medium))
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 8, weight: .semibold))
                }
                .foregroundStyle(.secondary)
            }
        }
    }

    private var updatedString: String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: entry.date)
    }
}
