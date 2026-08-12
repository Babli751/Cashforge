import Foundation

@MainActor
final class AuthService: ObservableObject {
    @Published var isSignedIn: Bool = false
    @Published var isWorking: Bool = false
    @Published var errorMessage: String?
    @Published var personalInfo: PersonalInfo?

    private let tokenKey = "authToken"
    private let apiBaseURL: String
    private let profileInfoService = ProfileInfoService()

    var token: String? {
        get { KeychainStore.get(tokenKey) }
        set {
            if let newValue {
                KeychainStore.set(newValue, forKey: tokenKey)
            } else {
                KeychainStore.delete(tokenKey)
            }
            isSignedIn = newValue != nil
        }
    }

    init() {
        apiBaseURL = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String ?? ""
        isSignedIn = token != nil
        if isSignedIn {
            Task { await refreshPersonalInfo() }
        }
    }

    func register(email: String, password: String) async {
        await submit(path: "register", email: email, password: password)
    }

    func login(email: String, password: String) async {
        await submit(path: "login", email: email, password: password)
    }

    func signOut() {
        token = nil
        personalInfo = nil
    }

    /// Fetches the signed-in user's saved personal info and publishes it for any view to read
    /// (e.g. Profile showing the user's name instead of "Player").
    func refreshPersonalInfo() async {
        guard let token else { return }
        if case .success(let info) = await profileInfoService.fetchDetailed(token: token) {
            personalInfo = info
        }
    }

    func updatePersonalInfo(_ info: PersonalInfo) {
        personalInfo = info
    }

    private func submit(path: String, email: String, password: String) async {
        guard let url = URL(string: "\(apiBaseURL)/auth/\(path)") else {
            errorMessage = "Invalid server URL"
            return
        }
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["email": email, "password": password])

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                errorMessage = "Network error"
                return
            }
            if http.statusCode == 200 || http.statusCode == 201 {
                let decoded = try JSONDecoder().decode(AuthResponse.self, from: data)
                token = decoded.token
                await refreshPersonalInfo()
            } else {
                let decoded = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                errorMessage = decoded?.error ?? "Something went wrong"
            }
        } catch {
            errorMessage = "Network error: \(error.localizedDescription)"
        }
    }

    private struct AuthResponse: Decodable {
        let token: String
        let userId: String
    }

    private struct ErrorResponse: Decodable {
        let error: String
    }
}

/// Minimal Keychain wrapper for storing the auth token securely.
enum KeychainStore {
    static func set(_ value: String, forKey key: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
        var attributes = query
        attributes[kSecValueData as String] = data
        SecItemAdd(attributes as CFDictionary, nil)
    }

    static func get(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
