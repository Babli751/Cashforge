import Foundation

struct Advice: Identifiable {
    let id = UUID()
    let icon: String
    let text: String
}

/// Rule-based advisor: looks at current business numbers to surface the most relevant
/// piece of advice. No AI involved — just prioritized heuristics.
enum AdvisorEngine {
    static func advice(for business: BusinessState) -> Advice {
        // Priority 1: urgent financial problems.
        if business.cash < 100 && business.month > 1 {
            return Advice(icon: "exclamationmark.triangle.fill", text: "Cash is critically low. Avoid spending on growth this month — focus on revenue from your existing customers.")
        }
        if business.teamSize > 0 && business.customers < business.teamSize * 3 {
            return Advice(icon: "person.3.fill", text: "You're paying for \(business.teamSize) team member\(business.teamSize == 1 ? "" : "s") but only have \(business.customers) customers. Consider getting more customers or reducing team size.")
        }
        if business.customers == 0 {
            return Advice(icon: "person.badge.plus", text: "You have no customers yet. Getting your first customer matters more than anything else right now.")
        }

        // Priority 2: patterns from recent history — catches repeated mistakes a
        // single-month snapshot would miss.
        if let trendAdvice = trendBasedAdvice(business) {
            return trendAdvice
        }

        // Priority 3: general growth-stage advice.
        if business.projectedProfit < 0 {
            return Advice(icon: "chart.line.downtrend.xyaxis", text: "This month is projected to lose money. Review your last decision before advancing.")
        }
        if business.month <= 2 {
            return Advice(icon: "flag.checkered", text: "Early days — focus on getting your first few customers before spending on anything else.")
        }
        return Advice(icon: "chart.line.uptrend.xyaxis", text: "Business is stable. Consider reinvesting profit into growth: more customers or a better offer.")
    }

    /// Looks at the last 3 completed months to spot a losing streak or a stalled
    /// customer count — signals a repeated decision pattern isn't working.
    private static func trendBasedAdvice(_ business: BusinessState) -> Advice? {
        let recent = business.history.suffix(3)
        guard recent.count == 3 else { return nil }

        if recent.allSatisfy({ $0.profit < 0 }) {
            return Advice(icon: "repeat.circle.fill", text: "You've lost money 3 months in a row. Whatever you've been trying isn't working — consider a different approach instead of repeating it.")
        }

        let customerCounts = recent.map(\.customers)
        if let first = customerCounts.first, customerCounts.allSatisfy({ $0 == first }) {
            return Advice(icon: "chart.line.flattrend.xyaxis", text: "Your customer count hasn't moved in 3 months. Growth has stalled — try a different lever than what you've been doing.")
        }

        return nil
    }
}
