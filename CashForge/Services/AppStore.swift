import Foundation
import Combine

struct ScenarioResult {
    let summary: String
    let lesson: String
}

struct MonthAdvanceResult {
    let narrative: String
    let event: MarketEvent?
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
    private let gameCenterService = GameCenterService()
    private let businessStateKey = "businessState"
    private let playerProfileKey = "playerProfile"
    private var isSyncing = false

    init() {
        loadBusiness()
        loadPlayerProfile()
        updateStreak()
        gameCenterService.authenticate()
        Task { await loadVideos() }
    }

    /// Updates the daily play streak: increments if the player last played yesterday,
    /// resets to 1 if they skipped a day or more, and leaves it unchanged if they already
    /// played today.
    private func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let lastPlayed = playerProfile.lastPlayedDate else {
            playerProfile.currentStreak = 1
            playerProfile.lastPlayedDate = today
            return
        }
        let lastPlayedDay = calendar.startOfDay(for: lastPlayed)
        let daysSince = calendar.dateComponents([.day], from: lastPlayedDay, to: today).day ?? 0
        if daysSince == 0 {
            return
        } else if daysSince == 1 {
            playerProfile.currentStreak += 1
        } else {
            playerProfile.currentStreak = 1
        }
        playerProfile.lastPlayedDate = today
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

        gameCenterService.submitCashEarned(business.cash)
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

    /// One-time emergency loan to recover from bankruptcy instead of restarting. Costs future
    /// profit (added as debt via a lower starting cash) and can only be used once per business.
    @discardableResult
    func acceptBailout() -> Bool {
        guard business.isBankrupt, !business.hasUsedBailout else { return false }
        business.cash = 100
        business.isBankrupt = false
        business.hasUsedBailout = true
        return true
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
        business.customers = max(0, business.customers + softenedCustomerDelta(choice.customerDelta))
        business.pricePerCustomer = max(1, business.pricePerCustomer + choice.priceDelta)
        business.teamSize = max(0, business.teamSize + choice.teamDelta)
        applyLesson(choice.lesson)
        return ScenarioResult(summary: choice.resultSummary, lesson: choice.lesson)
    }

    /// Reduces the size of negative customer swings using accumulated product quality —
    /// better product = customers are more forgiving of setbacks. Positive deltas are untouched.
    private func softenedCustomerDelta(_ delta: Int) -> Int {
        guard delta < 0 else { return delta }
        let reduction = min(business.productQualityBoost * 0.05, 0.5)
        return Int(Double(delta) * (1 - reduction))
    }

    /// Spends cash on a growth category this month. Marketing has diminishing returns
    /// (sqrt curve) to discourage dumping all cash into one category; Product and Team
    /// build durable boosts that persist across months. There's no "Savings" spend —
    /// choosing to save means simply not calling this at all.
    @discardableResult
    func allocateBudget(_ category: BudgetCategory, amount: Double) -> Bool {
        guard amount > 0, amount <= business.cash else { return false }
        business.cash -= amount

        switch category {
        case .marketing:
            let newCustomers = Int((amount * 0.15).squareRoot() * 3)
            business.customers += newCustomers
        case .product:
            business.productQualityBoost += amount / 200
        case .team:
            business.opsCapacityBoost += amount / 200
        }
        return true
    }

    /// ~20% chance each month of a random market event nudging cash/customers outside
    /// the player's control — keeps outcomes from being fully predictable from choices alone.
    private func rollMarketEvent() -> MarketEvent? {
        guard Int.random(in: 0..<5) == 0, let event = MarketEvent.all.randomElement() else { return nil }
        business.cash += event.cashDelta
        business.customers = max(0, business.customers + softenedCustomerDelta(event.customerDelta))
        return event
    }

    @discardableResult
    func advanceMonth() -> MonthAdvanceResult {
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

        let event = rollMarketEvent()

        if business.cash < 0 {
            business.isBankrupt = true
        } else if revenue > Double(business.level) * 1000 {
            business.level += 1
        }

        let narrative = monthNarrative(revenue: revenue, expenses: expenses, profit: profit)
        return MonthAdvanceResult(narrative: narrative, event: event)
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
