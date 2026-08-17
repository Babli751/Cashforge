import GameKit

/// Wraps Game Center authentication and leaderboard score submission.
final class GameCenterService {
    static let cashEarnedLeaderboardID = "com.cashforge.leaderboard.cashearned"

    private(set) var isAuthenticated = false

    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            self?.isAuthenticated = (error == nil) && GKLocalPlayer.local.isAuthenticated
        }
    }

    func submitCashEarned(_ cash: Double) {
        guard isAuthenticated else { return }
        GKLeaderboard.submitScore(
            Int(cash),
            context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [Self.cashEarnedLeaderboardID]
        ) { _ in }
    }
}
