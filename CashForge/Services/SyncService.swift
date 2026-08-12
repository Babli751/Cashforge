import Foundation

/// Syncs BusinessState to and from the backend for signed-in users.
final class SyncService {
    private let apiBaseURL: String

    init() {
        apiBaseURL = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String ?? ""
    }

    func fetchBusiness(token: String) async -> BusinessState? {
        guard let url = URL(string: "\(apiBaseURL)/me/business") else { return nil }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse, http.statusCode == 200,
              let wrapper = try? JSONDecoder().decode(BusinessStateWrapper.self, from: data) else {
            return nil
        }
        return wrapper.state
    }

    @discardableResult
    func saveBusiness(_ business: BusinessState, token: String) async -> Bool {
        guard let url = URL(string: "\(apiBaseURL)/me/business") else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["state": business])

        guard let (_, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse else {
            return false
        }
        return http.statusCode == 204
    }

    private struct BusinessStateWrapper: Decodable {
        let state: BusinessState?
    }
}
