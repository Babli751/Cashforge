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

        // Priority 2: general growth-stage advice.
        if business.projectedProfit < 0 {
            return Advice(icon: "chart.line.downtrend.xyaxis", text: "This month is projected to lose money. Review your last decision before advancing.")
        }
        if business.month <= 2 {
            return Advice(icon: "flag.checkered", text: "Early days — focus on getting your first few customers before spending on anything else.")
        }
        return Advice(icon: "chart.line.uptrend.xyaxis", text: "Business is stable. Consider reinvesting profit into growth: more customers or a better offer.")
    }
}
