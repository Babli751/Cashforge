import Foundation

struct PersonalInfo: Codable, Equatable {
    var fullName: String = ""
    var phoneNumber: String = ""
    var addressLine: String = ""
    var city: String = ""
    var country: String = ""
}

/// Fetches and saves the signed-in user's personal info (name, phone, address) to the backend.
final class ProfileInfoService {
    private let apiBaseURL: String

    init() {
        apiBaseURL = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String ?? ""
    }

    enum FetchOutcome {
        case success(email: String, info: PersonalInfo)
        case failure(String)
    }

    func fetchDetailed(token: String) async -> FetchOutcome {
        guard let url = URL(string: "\(apiBaseURL)/me/profile") else {
            return .failure("Invalid URL: \(apiBaseURL)")
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return .failure("No HTTP response")
            }
            let bodyText = String(data: data, encoding: .utf8) ?? "<binary>"
            guard http.statusCode == 200 else {
                return .failure("HTTP \(http.statusCode): \(bodyText)")
            }
            do {
                let decoded = try JSONDecoder().decode(ProfileResponse.self, from: data)
                let info = PersonalInfo(
                    fullName: decoded.fullName ?? "",
                    phoneNumber: decoded.phoneNumber ?? "",
                    addressLine: decoded.addressLine ?? "",
                    city: decoded.city ?? "",
                    country: decoded.country ?? ""
                )
                return .success(email: decoded.email, info: info)
            } catch {
                return .failure("Decode error: \(error). Body: \(bodyText)")
            }
        } catch {
            return .failure("Network error: \(error)")
        }
    }

    func fetch(token: String) async -> PersonalInfo? {
        if case .success(_, let info) = await fetchDetailed(token: token) {
            return info
        }
        return nil
    }

    @discardableResult
    func save(_ info: PersonalInfo, token: String) async -> Bool {
        guard let url = URL(string: "\(apiBaseURL)/me/profile") else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(info)

        guard let (_, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse else {
            return false
        }
        return http.statusCode == 204
    }

    enum CredentialUpdateOutcome {
        case success
        case failure(String)
    }

    /// Changes the signed-in user's email. The backend re-verifies currentPassword server-side.
    func updateEmail(newEmail: String, currentPassword: String, token: String) async -> CredentialUpdateOutcome {
        await putCredential(path: "/me/email", body: ["newEmail": newEmail, "currentPassword": currentPassword], token: token)
    }

    /// Changes the signed-in user's password. The backend re-verifies currentPassword server-side.
    func updatePassword(newPassword: String, currentPassword: String, token: String) async -> CredentialUpdateOutcome {
        await putCredential(path: "/me/password", body: ["newPassword": newPassword, "currentPassword": currentPassword], token: token)
    }

    private func putCredential(path: String, body: [String: String], token: String) async -> CredentialUpdateOutcome {
        guard let url = URL(string: "\(apiBaseURL)\(path)") else { return .failure("Invalid URL") }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return .failure("No HTTP response") }
            if http.statusCode == 204 { return .success }
            let decoded = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            return .failure(decoded?.error ?? "Update failed")
        } catch {
            return .failure("Network error: \(error.localizedDescription)")
        }
    }

    private struct ErrorResponse: Decodable {
        let error: String
    }

    private struct ProfileResponse: Decodable {
        let email: String
        let fullName: String?
        let phoneNumber: String?
        let addressLine: String?
        let city: String?
        let country: String?
    }
}
