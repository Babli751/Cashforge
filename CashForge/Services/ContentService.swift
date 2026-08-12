import Foundation

/// Fetches video/summary content from the CashForge API (Node/Express + Postgres).
/// Admin panel (separate web app) edits that data via the same API.
final class ContentService {
    private let apiBaseURL: String

    init() {
        apiBaseURL = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String ?? ""
    }

    func fetchVideos() async throws -> [VideoItem] {
        guard !apiBaseURL.isEmpty, let url = URL(string: "\(apiBaseURL)/videos") else {
            return Self.placeholderVideos
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            return Self.placeholderVideos
        }
        return try JSONDecoder().decode([VideoItem].self, from: data)
    }

    static let placeholderVideos: [VideoItem] = [
        VideoItem(
            id: "sample-1",
            title: "How To Get Your First Customer",
            videoURL: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
            teaser: "The fastest path from zero to your first paying customer.",
            summaryMarkdown: "Main Idea: Sell before you build.\n\nTalk to potential customers before building anything, sell the outcome instead of the product, and charge before delivering.",
            keyPoints: ["Sell before you build", "Talk to 10 potential customers first", "Charge before delivering"],
            thumbnailURL: nil
        )
    ]
}
