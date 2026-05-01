import Foundation

actor StatusFetcher {
    static let shared = StatusFetcher()

    private let summaryURL   = URL(string: "https://status.claude.com/api/v2/summary.json")!
    private let incidentsURL = URL(string: "https://status.claude.com/api/v2/incidents.json")!

    func fetchAll() async -> StatusBundle {
        async let s: StatusSummary?  = fetchOne(summaryURL)
        async let l: IncidentsList?  = fetchOne(incidentsURL)
        let (sum, list) = await (s, l)
        return StatusBundle(
            summary: sum,
            incidents: list?.incidents ?? [],
            fetchedAt: Date(),
            error: sum == nil && list == nil
        )
    }

    private func fetchOne<T: Decodable>(_ url: URL) async -> T? {
        do {
            var req = URLRequest(url: url)
            req.cachePolicy = .reloadIgnoringLocalCacheData
            req.timeoutInterval = 10
            req.setValue("ClaudeStatusWidget/1.0", forHTTPHeaderField: "User-Agent")
            let (data, _) = try await URLSession.shared.data(for: req)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            return nil
        }
    }
}
