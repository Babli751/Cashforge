import Foundation
import StoreKit

/// Wraps StoreKit2 for one-time unlocks, subscription, and lifetime access.
final class PurchaseService {
    static let subscriptionProductID = "com.cashforge.subscription.monthly"
    static let lifetimeProductID = "com.cashforge.lifetime"

    private let unlockedKey = "unlockedVideoIDs"

    func isUnlocked(videoID: String) -> Bool {
        if hasLifetimeOrSubscription() { return true }
        return unlockedVideoIDs().contains(videoID)
    }

    func purchaseUnlock(videoID: String) async -> Bool {
        let productID = "com.cashforge.unlock.\(videoID)"
        do {
            guard let product = try await Product.products(for: [productID]).first else {
                return false
            }
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified = verification {
                    markUnlocked(videoID)
                    return true
                }
                return false
            default:
                return false
            }
        } catch {
            return false
        }
    }

    func purchaseSubscription() async -> Bool {
        await purchase(productID: Self.subscriptionProductID)
    }

    func purchaseLifetime() async -> Bool {
        await purchase(productID: Self.lifetimeProductID)
    }

    private func purchase(productID: String) async -> Bool {
        do {
            guard let product = try await Product.products(for: [productID]).first else {
                return false
            }
            let result = try await product.purchase()
            if case .success(let verification) = result, case .verified = verification {
                UserDefaults.standard.set(true, forKey: productID)
                return true
            }
            return false
        } catch {
            return false
        }
    }

    private func hasLifetimeOrSubscription() -> Bool {
        UserDefaults.standard.bool(forKey: Self.lifetimeProductID)
            || UserDefaults.standard.bool(forKey: Self.subscriptionProductID)
    }

    private func unlockedVideoIDs() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: unlockedKey) ?? [])
    }

    private func markUnlocked(_ videoID: String) {
        var ids = unlockedVideoIDs()
        ids.insert(videoID)
        UserDefaults.standard.set(Array(ids), forKey: unlockedKey)
    }
}
