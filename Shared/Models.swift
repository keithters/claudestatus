import Foundation

struct StatusSummary: Codable, Sendable {
    let page: Page
    let status: StatusIndicator
    let components: [Component]
}

struct Page: Codable, Sendable {
    let name: String
    let updated_at: String?
}

struct StatusIndicator: Codable, Sendable {
    let indicator: String   // none | minor | major | critical | maintenance
    let description: String
}

struct Component: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let status: String      // operational | degraded_performance | partial_outage | major_outage | under_maintenance
    let position: Int
    let only_show_if_degraded: Bool?
}

struct Incident: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let status: String?
    let impact: String?
    let created_at: String?
    let updated_at: String?
    let resolved_at: String?
    let shortlink: String?

    var isResolved: Bool {
        switch (status ?? "").lowercased() {
        case "resolved", "postmortem", "completed": return true
        default: return false
        }
    }
}

struct IncidentsList: Codable, Sendable {
    let incidents: [Incident]
}

struct StatusBundle: Sendable {
    let summary: StatusSummary?
    let incidents: [Incident]
    let fetchedAt: Date
    let error: Bool
}
