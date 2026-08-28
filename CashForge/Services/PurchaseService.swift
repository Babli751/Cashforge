import Foundation
import StoreKit

/// Wraps StoreKit2 for one-time unlocks, subscription, and lifetime access.
///
/// All purchase state is namespaced by the signed-in user's ID so that switching
/// accounts on the same device (or playing as a fresh guest) never inherits another
/// account's unlocks — an app-wide guest account with no ID gets no persisted purchases.
final class PurchaseService {
    static let subscriptionProductID = "com.cashforge.subscription.monthly"
    static let lifetimeProductID = "com.cashforge.lifetime"

    var currentUserId: String?

    private func namespaced(_ key: String) -> String? {
        guard let currentUserId else { return nil }
        return "\(currentUserId).\(key)"
    }

    /// All videos are unlocked together — there is no per-video purchase, just this one check.
    func isUnlocked(videoID: String) -> Bool {
        hasLifetimeOrSubscription()
    }

    enum PurchaseOutcome: Equatable {
        case success
        case cancelled
        case pending
        case productUnavailable
        case verificationFailed
        case error(String)
    }

    /// Unlocking any video purchases the single "Lifetime Access" product (com.cashforge.lifetime),
    /// which grants access to all videos at once — there is no per-video product. The videoID
    /// parameter only exists to keep the call site readable at the point of purchase.
    @discardableResult
    func purchaseUnlock(videoID: String) async -> PurchaseOutcome {
        await purchase(productID: Self.lifetimeProductID)
    }

    @discardableResult
    func purchaseSubscription() async -> PurchaseOutcome {
        await purchase(productID: Self.subscriptionProductID)
    }

    @discardableResult
    func purchaseLifetime() async -> PurchaseOutcome {
        await purchase(productID: Self.lifetimeProductID)
    }

    private func purchase(productID: String) async -> PurchaseOutcome {
        guard let key = namespaced(productID) else { return .error("Not signed in") }
        do {
            guard let product = try await Product.products(for: [productID]).first else {
                return .productUnavailable
            }
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified = verification {
                    UserDefaults.standard.set(true, forKey: key)
                    return .success
                }
                return .verificationFailed
            case .userCancelled:
                return .cancelled
            case .pending:
                return .pending
            @unknown default:
                return .error("Unknown purchase result")
            }
        } catch {
            return .error(error.localizedDescription)
        }
    }

    private func hasLifetimeOrSubscription() -> Bool {
        guard let lifetimeKey = namespaced(Self.lifetimeProductID),
              let subscriptionKey = namespaced(Self.subscriptionProductID) else { return false }
        return UserDefaults.standard.bool(forKey: lifetimeKey)
            || UserDefaults.standard.bool(forKey: subscriptionKey)
    }
}
