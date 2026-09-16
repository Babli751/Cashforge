import Foundation
import StoreKit

/// Wraps StoreKit2 for the single "Lifetime Access" purchase that unlocks all videos.
///
/// Purchase state is device-local, not tied to any CashForge account — sign-in is not
/// required to buy or use this unlock (Apple requires non-account-based IAP content to be
/// purchasable without registration). StoreKit's own receipt/Apple ID association is what
/// makes "Restore Purchases" work across devices signed into the same Apple ID.
final class PurchaseService {
    static let lifetimeProductID = "com.cashforge.lifetime"

    /// All videos are unlocked together — there is no per-video purchase, just this one check.
    func isUnlocked(videoID: String) -> Bool {
        hasLifetime()
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
    func purchaseLifetime() async -> PurchaseOutcome {
        await purchase(productID: Self.lifetimeProductID)
    }

    private func purchase(productID: String) async -> PurchaseOutcome {
        do {
            guard let product = try await Product.products(for: [productID]).first else {
                return .productUnavailable
            }
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified = verification {
                    UserDefaults.standard.set(true, forKey: productID)
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

    private func hasLifetime() -> Bool {
        UserDefaults.standard.bool(forKey: Self.lifetimeProductID)
    }
}
