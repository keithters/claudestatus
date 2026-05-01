import SwiftUI

enum Palette {
    static func indicator(_ s: String) -> Color {
        switch s.lowercased() {
        case "none":        return Color(red: 0.13, green: 0.77, blue: 0.37)
        case "minor":       return Color(red: 0.92, green: 0.70, blue: 0.03)
        case "major":       return Color(red: 0.98, green: 0.45, blue: 0.09)
        case "critical":    return Color(red: 0.94, green: 0.27, blue: 0.27)
        case "maintenance": return Color(red: 0.23, green: 0.51, blue: 0.96)
        default:            return .gray
        }
    }

    static func component(_ s: String) -> Color {
        switch s.lowercased() {
        case "operational":          return Color(red: 0.13, green: 0.77, blue: 0.37)
        case "degraded_performance": return Color(red: 0.92, green: 0.70, blue: 0.03)
        case "partial_outage":       return Color(red: 0.98, green: 0.45, blue: 0.09)
        case "major_outage":         return Color(red: 0.94, green: 0.27, blue: 0.27)
        case "under_maintenance":    return Color(red: 0.23, green: 0.51, blue: 0.96)
        default:                     return .gray
        }
    }
}

func friendly(_ s: String) -> String {
    s.replacingOccurrences(of: "_", with: " ").capitalized
}

private let isoWithFrac: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return f
}()
private let isoPlain = ISO8601DateFormatter()

func parseISO(_ s: String?) -> Date? {
    guard let s else { return nil }
    return isoWithFrac.date(from: s) ?? isoPlain.date(from: s)
}

func severityRank(_ s: String?) -> Int {
    switch (s ?? "").lowercased() {
    case "critical":    return 4
    case "major":       return 3
    case "minor":       return 2
    case "maintenance": return 1
    default:            return 0
    }
}

func relativeTime(_ iso: String?) -> String? {
    guard let iso, let d = parseISO(iso) else { return nil }
    let r = RelativeDateTimeFormatter()
    r.unitsStyle = .abbreviated
    return r.localizedString(for: d, relativeTo: Date())
}

func incidentDuration(_ i: Incident) -> String? {
    guard let start = parseISO(i.created_at) else { return nil }
    let endISO = i.isResolved ? (i.resolved_at ?? i.updated_at) : nil
    let end = endISO.flatMap(parseISO) ?? Date()
    let secs = end.timeIntervalSince(start)
    guard secs >= 0 else { return nil }
    let mins = Int((secs + 30) / 60)
    if mins < 1  { return "<1 min" }
    if mins < 60 { return "\(mins) min" }
    let h = mins / 60, m = mins % 60
    return m == 0 ? "\(h)h" : "\(h)h \(m)m"
}

func incidentMetaLine(_ i: Incident) -> String {
    var parts: [String] = []
    if let impact = i.impact, !["none", "maintenance"].contains(impact.lowercased()) {
        parts.append(impact.capitalized)
    }
    if let dur = incidentDuration(i) { parts.append(dur) }
    parts.append(i.isResolved ? "Resolved" : friendly(i.status ?? "Investigating"))
    let timeISO = i.isResolved ? (i.resolved_at ?? i.updated_at) : (i.updated_at ?? i.created_at)
    if let t = relativeTime(timeISO) { parts.append(t) }
    return parts.joined(separator: " · ")
}

struct RecentSeverity: Sendable {
    let impact: String
    let label: String
    let timeAgo: String
    let color: Color
}

func recentSeverity(in incidents: [Incident], hours: TimeInterval = 24) -> RecentSeverity? {
    let cutoff = Date().addingTimeInterval(-hours * 3600)
    var best: (Incident, Date)?
    for i in incidents {
        guard let when = parseISO(i.resolved_at ?? i.updated_at ?? i.created_at),
              when >= cutoff else { continue }
        if best == nil || severityRank(i.impact) > severityRank(best!.0.impact) {
            best = (i, when)
        }
    }
    guard let (incident, when) = best,
          severityRank(incident.impact) >= 3 else { return nil }

    let r = RelativeDateTimeFormatter()
    r.unitsStyle = .abbreviated
    let timeAgo = r.localizedString(for: when, relativeTo: Date())
    let impact = (incident.impact ?? "").lowercased()
    return RecentSeverity(
        impact: impact,
        label: "\(impact.capitalized) outage",
        timeAgo: timeAgo,
        color: Palette.indicator(impact)
    )
}
