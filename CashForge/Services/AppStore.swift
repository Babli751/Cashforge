import Foundation
import Combine

struct ScenarioResult {
    let summary: String
    let lesson: String
}

@MainActor
final class AppStore: ObservableObject {
    @Published var videos: [VideoItem] = []
    @Published var business = BusinessState() {
        didSet { saveBusiness() }
    }
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedTab: Int = 0
    @Published var playerProfile = PlayerProfile() {
        didSet { savePlayerProfile() }
    }

    let authService = AuthService()

    private let contentService = ContentService()
    private let purchaseService = PurchaseService()
    private let syncService = SyncService()
    private let businessStateKey = "businessState"
    private let playerProfileKey = "playerProfile"
    private var isSyncing = false

    init() {
        loadBusiness()
        loadPlayerProfile()
        Task { await loadVideos() }
    }

    /// Called after a successful sign-in: fetches the account's saved progress from the backend
    /// if any, otherwise starts a fresh business tied to the new account (signing in does not
    /// carry over local guest progress).
    func syncAfterSignIn() async {
        guard let token = authService.token else { return }
        isSyncing = true
        defer { isSyncing = false }
        if let remote = await syncService.fetchBusiness(token: token) {
            business = remote
        } else {
            business = BusinessState()
        }
        refreshUnlockState()
    }

    private func loadBusiness() {
        guard let data = UserDefaults.standard.data(forKey: businessStateKey),
              let decoded = try? JSONDecoder().decode(BusinessState.self, from: data) else { return }
        business = decoded
    }

    private func saveBusiness() {
        guard let data = try? JSONEncoder().encode(business) else { return }
        UserDefaults.standard.set(data, forKey: businessStateKey)

        if !isSyncing, let token = authService.token {
            let snapshot = business
            Task { await syncService.saveBusiness(snapshot, token: token) }
        }
    }

    private func loadPlayerProfile() {
        guard let data = UserDefaults.standard.data(forKey: playerProfileKey),
              let decoded = try? JSONDecoder().decode(PlayerProfile.self, from: data) else { return }
        playerProfile = decoded
    }

    private func savePlayerProfile() {
        guard let data = try? JSONEncoder().encode(playerProfile) else { return }
        UserDefaults.standard.set(data, forKey: playerProfileKey)
    }

    func loadVideos() async {
        isLoading = true
        defer { isLoading = false }
        do {
            var items = try await contentService.fetchVideos()
            for i in items.indices {
                items[i].isUnlocked = isEffectivelyUnlocked(items[i].id)
            }
            videos = items
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// A video only counts as unlocked when the player is signed in — guests always see
    /// videos as locked, even if this device previously purchased an unlock while signed in.
    private func isEffectivelyUnlocked(_ videoID: String) -> Bool {
        authService.isSignedIn && purchaseService.isUnlocked(videoID: videoID)
    }

    /// Recomputes lock state for all loaded videos — call after sign-in/sign-out changes.
    func refreshUnlockState() {
        for i in videos.indices {
            videos[i].isUnlocked = isEffectivelyUnlocked(videos[i].id)
        }
    }

    func unlock(_ video: VideoItem) async -> Bool {
        guard authService.isSignedIn else { return false }
        let success = await purchaseService.purchaseUnlock(videoID: video.id)
        if success, let idx = videos.firstIndex(where: { $0.id == video.id }) {
            videos[idx].isUnlocked = true
        }
        return success
    }

    func applyLesson(_ lesson: String) {
        guard !business.appliedLessons.contains(lesson) else { return }
        business.appliedLessons.append(lesson)
    }

    func startBusiness(_ type: BusinessType) {
        var fresh = BusinessState()
        fresh.hasStarted = true
        fresh.businessType = type
        fresh.cash = type.startingCash
        fresh.appliedLessons = business.appliedLessons
        business = fresh
    }

    /// The scenario for the current month, cycling through the business type's curriculum in order.
    var currentScenario: Scenario? {
        guard let type = business.businessType else { return nil }
        let scenarios = type.scenarios
        guard !scenarios.isEmpty else { return nil }
        return scenarios[business.lessonIndex % scenarios.count]
    }

    /// Applies the chosen scenario's effects immediately and returns the result to show in a popup.
    /// The month does not advance here — that happens explicitly via advanceMonth().
    @discardableResult
    func resolveScenario(_ choice: ScenarioChoice) -> ScenarioResult {
        business.cash += choice.cashDelta
        business.customers = max(0, business.customers + choice.customerDelta)
        business.pricePerCustomer = max(1, business.pricePerCustomer + choice.priceDelta)
        business.teamSize = max(0, business.teamSize + choice.teamDelta)
        applyLesson(choice.lesson)
        return ScenarioResult(summary: choice.resultSummary, lesson: choice.lesson)
    }

    @discardableResult
    func advanceMonth() -> String {
        let revenue = business.projectedRevenue
        let expenses = business.projectedExpenses
        let profit = revenue - expenses

        business.cash += profit
        business.lastMonthRevenue = revenue
        business.lastMonthExpenses = expenses
        business.lastMonthProfit = profit

        business.history.append(MonthRecord(
            month: business.month,
            revenue: revenue,
            expenses: expenses,
            profit: profit,
            customers: business.customers,
            cashAfter: business.cash
        ))

        business.month += 1
        business.lessonIndex += 1

        if business.cash < 0 {
            business.isBankrupt = true
        } else if revenue > Double(business.level) * 1000 {
            business.level += 1
        }

        return monthNarrative(revenue: revenue, expenses: expenses, profit: profit)
    }

    private func monthNarrative(revenue: Double, expenses: Double, profit: Double) -> String {
        if expenses > revenue {
            return "Expenses ($\(Int(expenses))) were higher than revenue ($\(Int(revenue))) this month — you're spending faster than you're earning."
        } else if profit > 0 {
            return "You made $\(Int(profit)) in profit this month."
        } else {
            return "You broke even this month."
        }
    }
}
