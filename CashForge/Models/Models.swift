import Foundation

struct VideoItem: Identifiable, Codable, Hashable {
    var id: String
    var title: String
    var videoURL: String
    var teaser: String
    var summaryMarkdown: String
    var keyPoints: [String]
    var thumbnailURL: String?
    var isUnlocked: Bool = false

    enum CodingKeys: String, CodingKey {
        case id, title, videoURL, teaser, summaryMarkdown, keyPoints, thumbnailURL
    }

    /// Extracts the YouTube video ID from common YouTube URL formats, if this is a YouTube link.
    var youtubeID: String? {
        guard let url = URL(string: videoURL), let host = url.host?.lowercased() else { return nil }
        if host.contains("youtu.be") {
            return url.pathComponents.dropFirst().first
        }
        if host.contains("youtube.com") {
            if url.path == "/watch", let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                return components.queryItems?.first(where: { $0.name == "v" })?.value
            }
            if url.path.hasPrefix("/embed/") {
                return String(url.path.dropFirst("/embed/".count))
            }
        }
        return nil
    }

    /// Best URL to load in the player: converts YouTube links to embed form, passes others through as-is.
    /// Uses youtube-nocookie.com and playsinline=1 to avoid embed errors inside WKWebView.
    var embedURL: URL? {
        if let ytID = youtubeID {
            return URL(string: "https://www.youtube-nocookie.com/embed/\(ytID)?playsinline=1")
        }
        return URL(string: videoURL)
    }
}

struct BusinessState: Codable {
    var hasStarted: Bool = false
    var businessType: BusinessType?
    var name: String = "My Business"
    var level: Int = 1
    var cash: Double = 0
    var customers: Int = 0
    var pricePerCustomer: Double = 20
    var teamSize: Int = 0
    var month: Int = 1
    var lessonIndex: Int = 0
    var appliedLessons: [String] = []
    var lastMonthRevenue: Double = 0
    var lastMonthExpenses: Double = 0
    var lastMonthProfit: Double = 0
    var lastMonthCustomerDelta: Int = 0
    var isBankrupt: Bool = false
    var history: [MonthRecord] = []

    static let salaryPerHire: Double = 150
    static let fixedMonthlyCost: Double = 50

    var projectedRevenue: Double {
        Double(customers) * pricePerCustomer
    }

    var projectedExpenses: Double {
        Double(teamSize) * Self.salaryPerHire + Self.fixedMonthlyCost
    }

    var projectedProfit: Double {
        projectedRevenue - projectedExpenses
    }
}

struct MonthRecord: Codable, Identifiable {
    var id = UUID()
    var month: Int
    var revenue: Double
    var expenses: Double
    var profit: Double
    var customers: Int
    var cashAfter: Double
}

enum BusinessType: String, CaseIterable, Identifiable, Codable {
    case app = "Build an App"
    case freelance = "Freelance Services"
    case reselling = "Reselling Products"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .app: return "Build something once, sell it to many people."
        case .freelance: return "Sell your time and skills directly to clients."
        case .reselling: return "Buy low, sell high — physical or digital products."
        }
    }

    var icon: String {
        switch self {
        case .app: return "iphone"
        case .freelance: return "person.fill.checkmark"
        case .reselling: return "shippingbox.fill"
        }
    }

    /// Starting conditions: how you earn your first $500 before "real" business stats kick in.
    var startingCash: Double {
        switch self {
        case .app: return 200
        case .freelance: return 0
        case .reselling: return 300
        }
    }

    var firstStepAdvice: String {
        switch self {
        case .app:
            return "You have $200 saved. Spend it wisely on your first month — apps take longer to get customers but each one costs little to serve."
        case .freelance:
            return "You start with $0 but freelancing has no upfront cost — your time is the product. Land your first client through organic outreach."
        case .reselling:
            return "You have $300 to buy initial inventory. Price matters a lot here — customers compare prices easily."
        }
    }

    var scenarios: [Scenario] {
        switch self {
        case .app: return Self.appScenarios
        case .freelance: return Self.freelanceScenarios
        case .reselling: return Self.resellingScenarios
        }
    }

    private static let appScenarios: [Scenario] = [
        Scenario(
            id: "app_trust",
            lessonTitle: "Risk-Reversal",
            prompt: "Users are downloading your app but not upgrading to paid. Reviews mention they're not sure it's worth it yet.",
            choices: [
                ScenarioChoice(title: "Lower the price", detail: "Drop price by $5", cashDelta: 0, customerDelta: 3, priceDelta: -5, teamDelta: 0, resultSummary: "Lower barrier to entry brought in a few more upgrades.", lesson: "Cutting price can boost volume, but it also trains users to expect a discount — it doesn't fix trust, it just avoids the problem."),
                ScenarioChoice(title: "Add a free trial", detail: "7-day free trial, no cost", cashDelta: 0, customerDelta: 8, priceDelta: 0, teamDelta: 0, resultSummary: "Trial users converted at a much higher rate once they saw the value.", lesson: "Letting people experience the value before paying (risk-reversal) usually beats discounting — it solves the actual trust problem, not just the price objection."),
                ScenarioChoice(title: "Do nothing, wait for reviews", detail: "No cost", cashDelta: 0, customerDelta: 0, priceDelta: 0, teamDelta: 0, resultSummary: "Growth stalled while trust built naturally, slower than the other options.", lesson: "Ignoring a trust problem doesn't make it go away — inaction has a real cost too, even if it's just lost time.")
            ]
        ),
        Scenario(
            id: "app_bug",
            lessonTitle: "Technical Debt",
            prompt: "A bug is causing crashes for some users. Fixing it well takes time and money.",
            choices: [
                ScenarioChoice(title: "Quick patch now", detail: "$50, partial fix", cashDelta: -50, customerDelta: 2, priceDelta: 0, teamDelta: 0, resultSummary: "Crashes reduced but not eliminated.", lesson: "Fast fixes stop the bleeding but often leave root causes — technical debt you'll pay for later."),
                ScenarioChoice(title: "Proper fix", detail: "$200, full fix", cashDelta: -200, customerDelta: 6, priceDelta: 0, teamDelta: 0, resultSummary: "Crashes stopped completely, reviews improved.", lesson: "Investing in quality costs more upfront but protects your reputation — in software, reliability is part of the product."),
                ScenarioChoice(title: "Ignore it, focus on growth", detail: "No cost", cashDelta: 0, customerDelta: -6, priceDelta: 0, teamDelta: 0, resultSummary: "Bad reviews piled up and new downloads slowed.", lesson: "Growing on top of a broken product usually backfires — bugs compound into reputation damage.")
            ]
        ),
        Scenario(
            id: "app_competitor",
            lessonTitle: "Positioning vs. Price Wars",
            prompt: "A competitor just launched a similar app at half your price.",
            choices: [
                ScenarioChoice(title: "Match their price", detail: "Cut price to compete", cashDelta: 0, customerDelta: 4, priceDelta: -8, teamDelta: 0, resultSummary: "Kept some price-sensitive users, but revenue per user dropped hard.", lesson: "Racing to the bottom on price is a trap — you can win the customer and lose the business."),
                ScenarioChoice(title: "Highlight what's different", detail: "$100 on messaging/positioning", cashDelta: -100, customerDelta: 5, priceDelta: 0, teamDelta: 0, resultSummary: "Customers who valued your specific features stayed and even a few switched over.", lesson: "Competing on differentiation instead of price protects your margin — this is called positioning."),
                ScenarioChoice(title: "Ignore them", detail: "No cost", cashDelta: 0, customerDelta: -3, priceDelta: 0, teamDelta: 0, resultSummary: "Lost some price-sensitive customers to the competitor.", lesson: "Not every competitive threat needs a reaction, but ignoring all of them eventually costs you market share.")
            ]
        ),
        Scenario(
            id: "app_scale",
            lessonTitle: "Operational Capacity",
            prompt: "Downloads are growing but your server costs and support load are growing with them.",
            choices: [
                ScenarioChoice(title: "Hire support help", detail: "Adds team member", cashDelta: 0, customerDelta: 2, priceDelta: 0, teamDelta: 1, resultSummary: "Response times improved, users noticed the better support.", lesson: "Scaling a business isn't just marketing — operational capacity has to grow with demand or quality drops."),
                ScenarioChoice(title: "Automate with a help bot", detail: "$150 one-time", cashDelta: -150, customerDelta: 3, priceDelta: 0, teamDelta: 0, resultSummary: "Handled routine questions without adding headcount.", lesson: "Automation can substitute for hiring at this stage — a smart tradeoff when volume is moderate.")
            ]
        ),
        Scenario(
            id: "app_retention",
            lessonTitle: "Retention vs. Acquisition",
            prompt: "You're spending heavily on ads, but just as many existing users are churning each month.",
            choices: [
                ScenarioChoice(title: "Spend more on ads to offset churn", detail: "$300", cashDelta: -300, customerDelta: 6, priceDelta: 0, teamDelta: 0, resultSummary: "Replaced the churned users, but at a real cost every month.", lesson: "Buying your way past churn is expensive and never-ending — it treats the symptom, not the disease."),
                ScenarioChoice(title: "Investigate why users leave", detail: "$100 for user research", cashDelta: -100, customerDelta: 4, priceDelta: 0, teamDelta: 0, resultSummary: "Found the drop-off point and fixed it, churn slowed.", lesson: "It's usually cheaper to keep an existing customer than acquire a new one — retention compounds, acquisition doesn't.")
            ]
        ),
        Scenario(
            id: "app_pricing_tiers",
            lessonTitle: "Market Segmentation",
            prompt: "Some users would pay much more for advanced features, while others just want the basics for cheap.",
            choices: [
                ScenarioChoice(title: "Keep one flat price", detail: "No cost", cashDelta: 0, customerDelta: 0, priceDelta: 0, teamDelta: 0, resultSummary: "Simple, but you left money on the table from power users.", lesson: "A single price point often underserves both ends of your market — high-value users and price-sensitive ones."),
                ScenarioChoice(title: "Launch tiered pricing", detail: "$150 to build tiers", cashDelta: -150, customerDelta: 5, priceDelta: 6, teamDelta: 0, resultSummary: "Power users upgraded to the higher tier, casual users stayed on basic.", lesson: "Segmenting customers by what they value lets you capture more revenue without losing price-sensitive buyers.")
            ]
        ),
        Scenario(
            id: "app_team_conflict",
            lessonTitle: "Culture Compounds",
            prompt: "Your growing team is starting to disagree on priorities — features vs. bug fixes vs. marketing.",
            choices: [
                ScenarioChoice(title: "Let everyone work on what they want", detail: "No cost", cashDelta: 0, customerDelta: -3, priceDelta: 0, teamDelta: 0, resultSummary: "Team scattered effort across too many things, progress slowed.", lesson: "Without clear priorities, even a good team can work hard and go nowhere — alignment matters as much as talent."),
                ScenarioChoice(title: "Set one clear priority for the month", detail: "No cost", cashDelta: 0, customerDelta: 5, priceDelta: 0, teamDelta: 0, resultSummary: "Focused effort on one thing produced visible results.", lesson: "As a business grows, leadership shifts from doing the work to deciding what work matters most.")
            ]
        )
    ]

    private static let freelanceScenarios: [Scenario] = [
        Scenario(
            id: "freelance_lowball",
            lessonTitle: "Price Signals Value",
            prompt: "A potential client says your rate is too high and offers half your price.",
            choices: [
                ScenarioChoice(title: "Accept their offer", detail: "Take the lower rate", cashDelta: 0, customerDelta: 2, priceDelta: -10, teamDelta: 0, resultSummary: "Got the client, but at a much lower rate than usual.", lesson: "Accepting lowball offers can anchor your rate down for future clients too — price signals value."),
                ScenarioChoice(title: "Hold your rate, explain value", detail: "No cost", cashDelta: 0, customerDelta: -1, priceDelta: 0, teamDelta: 0, resultSummary: "Lost this client, but kept your rate intact for everyone else.", lesson: "Holding firm on price filters out bad-fit clients — this protects your rate long-term even if it costs a sale today."),
                ScenarioChoice(title: "Offer a smaller scope instead", detail: "No cost", cashDelta: 0, customerDelta: 3, priceDelta: 0, teamDelta: 0, resultSummary: "Client accepted a smaller project at your full rate.", lesson: "Reducing scope instead of price protects your rate while still meeting the client's budget — a classic negotiation move.")
            ]
        ),
        Scenario(
            id: "freelance_scope_creep",
            lessonTitle: "Scope Boundaries",
            prompt: "A client keeps asking for 'just one more thing' outside the agreed project.",
            choices: [
                ScenarioChoice(title: "Do it for free to keep them happy", detail: "No cost, no extra pay", cashDelta: 0, customerDelta: -2, priceDelta: 0, teamDelta: 0, resultSummary: "Client was happy short-term, but you worked unpaid hours.", lesson: "Unpaid scope creep quietly erodes your effective hourly rate — it feels harmless but adds up."),
                ScenarioChoice(title: "Charge extra for the addition", detail: "No cost", cashDelta: 0, customerDelta: 1, priceDelta: 3, teamDelta: 0, resultSummary: "Client agreed to pay for the extra work — relationship stayed professional.", lesson: "Clear scope boundaries with paid add-ons is standard practice — it respects both your time and the client's budget."),
                ScenarioChoice(title: "Firmly decline", detail: "No cost", cashDelta: 0, customerDelta: -3, priceDelta: 0, teamDelta: 0, resultSummary: "Client was annoyed and didn't return for future work.", lesson: "Being too rigid can cost you repeat business — sometimes a small paid concession keeps the relationship alive.")
            ]
        ),
        Scenario(
            id: "freelance_burnout",
            lessonTitle: "Delegation vs. Capacity",
            prompt: "You've taken on too many clients this month and quality is starting to slip.",
            choices: [
                ScenarioChoice(title: "Push through solo", detail: "No cost", cashDelta: 0, customerDelta: -4, priceDelta: 0, teamDelta: 0, resultSummary: "Delivered late work, a client complained about quality.", lesson: "Overloading yourself as a solo freelancer has a ceiling — quality drops and reputation takes the hit."),
                ScenarioChoice(title: "Bring on a subcontractor", detail: "Adds team member", cashDelta: 0, customerDelta: 3, priceDelta: 0, teamDelta: 1, resultSummary: "Delegated some work and kept delivery quality up.", lesson: "Delegation is how solo work becomes a real business — it costs money but protects your capacity and reputation."),
                ScenarioChoice(title: "Turn down new work", detail: "No cost", cashDelta: 0, customerDelta: -5, priceDelta: 0, teamDelta: 0, resultSummary: "Fewer clients this month, but existing ones got your full attention.", lesson: "Saying no to protect quality is a legitimate strategy — sustainable growth beats short-term revenue spikes.")
            ]
        ),
        Scenario(
            id: "freelance_referral",
            lessonTitle: "Referral Economics",
            prompt: "A happy client offers to refer you to others — but only if you give them a discount for future work.",
            choices: [
                ScenarioChoice(title: "Accept the discount deal", detail: "No cost", cashDelta: 0, customerDelta: 5, priceDelta: -3, teamDelta: 0, resultSummary: "Got several new referred clients at a slightly lower average rate.", lesson: "Referrals are one of the cheapest ways to grow — a small discount can be worth the reduced acquisition cost."),
                ScenarioChoice(title: "Ask for referral without discount", detail: "No cost", cashDelta: 0, customerDelta: 2, priceDelta: 0, teamDelta: 0, resultSummary: "Got fewer referrals, but kept full rate.", lesson: "Not every referral needs an incentive — happy clients often refer for free if you simply ask.")
            ]
        ),
        Scenario(
            id: "freelance_retainer",
            lessonTitle: "Recurring Revenue",
            prompt: "A client who's hired you project-by-project asks if you'd consider an ongoing arrangement.",
            choices: [
                ScenarioChoice(title: "Stick to project-based work", detail: "No cost", cashDelta: 0, customerDelta: 0, priceDelta: 0, teamDelta: 0, resultSummary: "Kept flexibility, but income stayed unpredictable month to month.", lesson: "Project work gives flexibility but no predictability — you start from zero every month."),
                ScenarioChoice(title: "Set up a monthly retainer", detail: "No cost", cashDelta: 0, customerDelta: 3, priceDelta: 8, teamDelta: 0, resultSummary: "Locked in predictable income and a stronger relationship with the client.", lesson: "Recurring revenue (retainers, subscriptions) is more valuable than one-off income of the same size — it's predictable.")
            ]
        ),
        Scenario(
            id: "freelance_niche",
            lessonTitle: "Niching Down",
            prompt: "You've worked with all kinds of clients so far. A colleague suggests specializing in just one industry.",
            choices: [
                ScenarioChoice(title: "Stay a generalist", detail: "No cost", cashDelta: 0, customerDelta: 1, priceDelta: 0, teamDelta: 0, resultSummary: "Kept a wide client pool, but each pitch had to start from scratch.", lesson: "Generalists compete with everyone — it's often harder to stand out or command premium rates."),
                ScenarioChoice(title: "Specialize in one industry", detail: "No cost", cashDelta: 0, customerDelta: 2, priceDelta: 12, teamDelta: 0, resultSummary: "Became the obvious choice for that industry — clients paid a premium for the expertise.", lesson: "Niching down narrows who you can sell to, but makes you the obvious expert for that group — expertise commands higher prices.")
            ]
        ),
        Scenario(
            id: "freelance_agency",
            lessonTitle: "Trading Time for Leverage",
            prompt: "You have more client demand than you can personally handle, even after delegating some work.",
            choices: [
                ScenarioChoice(title: "Keep working solo hours", detail: "No cost", cashDelta: 0, customerDelta: -2, priceDelta: 0, teamDelta: 0, resultSummary: "Turned away work you couldn't fit in your own hours.", lesson: "A freelancer's income is capped by their own hours — there's a ceiling you hit eventually."),
                ScenarioChoice(title: "Build a small team, become an agency", detail: "No cost", cashDelta: 0, customerDelta: 6, priceDelta: 0, teamDelta: 2, resultSummary: "Took on more clients than you ever could alone, income grew past your personal limit.", lesson: "Moving from freelancer to agency trades some margin for leverage — you earn from others' time, not just your own.")
            ]
        )
    ]

    private static let resellingScenarios: [Scenario] = [
        Scenario(
            id: "reselling_stockout",
            lessonTitle: "Inventory Management",
            prompt: "Your best-selling item is out of stock and a competitor has it in stock.",
            choices: [
                ScenarioChoice(title: "Rush order at higher cost", detail: "$150", cashDelta: -150, customerDelta: 4, priceDelta: 0, teamDelta: 0, resultSummary: "Restocked fast and kept most customers from switching.", lesson: "Paying extra to avoid stockouts is often worth it — lost customers from stockouts rarely come back."),
                ScenarioChoice(title: "Wait for normal restock", detail: "No cost", cashDelta: 0, customerDelta: -6, priceDelta: 0, teamDelta: 0, resultSummary: "Several customers bought from the competitor instead.", lesson: "Inventory management directly impacts revenue — being out of stock is a hidden cost many resellers underestimate.")
            ]
        ),
        Scenario(
            id: "reselling_reviews",
            lessonTitle: "Fulfillment Is Part of the Product",
            prompt: "You got a couple of negative reviews about shipping speed.",
            choices: [
                ScenarioChoice(title: "Upgrade to faster shipping", detail: "$100/month ongoing", cashDelta: -100, customerDelta: 5, priceDelta: 0, teamDelta: 0, resultSummary: "Shipping complaints dropped, ratings improved.", lesson: "In reselling, fulfillment speed is part of the product experience — customers can't tell your product from your logistics."),
                ScenarioChoice(title: "Add a shipping delay notice", detail: "No cost", cashDelta: 0, customerDelta: 1, priceDelta: 0, teamDelta: 0, resultSummary: "Setting expectations upfront reduced complaints somewhat.", lesson: "Managing expectations is a cheap fix — customers tolerate slow shipping much better when they know about it in advance.")
            ]
        ),
        Scenario(
            id: "reselling_counterfeit_fear",
            lessonTitle: "Risk-Reversal",
            prompt: "Customers are asking if your products are authentic/genuine before buying.",
            choices: [
                ScenarioChoice(title: "Add authenticity guarantee", detail: "No cost", cashDelta: 0, customerDelta: 6, priceDelta: 0, teamDelta: 0, resultSummary: "Clear guarantees removed hesitation for many buyers.", lesson: "A guarantee costs nothing to offer but directly removes the buyer's biggest fear — this is risk-reversal in action."),
                ScenarioChoice(title: "Lower price to offset doubt", detail: "Drop price by $5", cashDelta: 0, customerDelta: 2, priceDelta: -5, teamDelta: 0, resultSummary: "Some price-sensitive buyers converted, but doubt remained for others.", lesson: "Discounting doesn't fix trust problems — it just makes the risk feel smaller, not solved.")
            ]
        ),
        Scenario(
            id: "reselling_bulk_deal",
            lessonTitle: "Cashflow vs. Margin",
            prompt: "A supplier offers you a bulk discount if you buy 3x your normal order size.",
            choices: [
                ScenarioChoice(title: "Take the bulk deal", detail: "$300 upfront", cashDelta: -300, customerDelta: 3, priceDelta: -2, teamDelta: 0, resultSummary: "Lower per-unit cost let you price more competitively.", lesson: "Bulk buying improves margins but ties up cash in inventory — this is a real cashflow tradeoff, not free money."),
                ScenarioChoice(title: "Stick with normal order size", detail: "No cost", cashDelta: 0, customerDelta: 0, priceDelta: 0, teamDelta: 0, resultSummary: "Kept cash flexible, missed the discount.", lesson: "Preserving cash flexibility has value too — not every discount is worth the capital commitment.")
            ]
        ),
        Scenario(
            id: "reselling_brand",
            lessonTitle: "Private Labeling",
            prompt: "You're reselling a generic product. A manufacturer offers to put your own brand on it for a bit more per unit.",
            choices: [
                ScenarioChoice(title: "Keep reselling the generic version", detail: "No cost", cashDelta: 0, customerDelta: 0, priceDelta: 0, teamDelta: 0, resultSummary: "Stayed easily replaceable — customers could buy the same item from anyone.", lesson: "Reselling generic products means customers have no reason to stay loyal to you specifically — you're competing purely on price."),
                ScenarioChoice(title: "Private-label your own brand", detail: "$200 setup cost", cashDelta: -200, customerDelta: 3, priceDelta: 5, teamDelta: 0, resultSummary: "Built a brand customers started to recognize and trust, could charge more.", lesson: "Private labeling turns a commodity into a brand — it costs more upfront but builds pricing power and loyalty.")
            ]
        ),
        Scenario(
            id: "reselling_returns",
            lessonTitle: "The Cost of Convenience",
            prompt: "Customers are asking for free, hassle-free returns — competitors already offer it.",
            choices: [
                ScenarioChoice(title: "Keep your current return policy", detail: "No cost", cashDelta: 0, customerDelta: -3, priceDelta: 0, teamDelta: 0, resultSummary: "Some hesitant buyers chose a competitor with easier returns instead.", lesson: "Buyer-unfriendly policies quietly cost you sales you never see — the lost customer just goes elsewhere silently."),
                ScenarioChoice(title: "Offer free returns", detail: "Ongoing cost built into margin", cashDelta: -50, customerDelta: 6, priceDelta: 0, teamDelta: 0, resultSummary: "More buyers converted since the risk of trying felt lower.", lesson: "Reducing purchase friction (like easy returns) often pays for itself in higher conversion — it's another form of risk-reversal.")
            ]
        ),
        Scenario(
            id: "reselling_seasonal",
            lessonTitle: "Demand Isn't Constant",
            prompt: "You're heading into a slow season where demand for your product historically drops.",
            choices: [
                ScenarioChoice(title: "Keep the same inventory levels", detail: "No cost", cashDelta: 0, customerDelta: -4, priceDelta: 0, teamDelta: 0, resultSummary: "Ended up with excess inventory sitting unsold.", lesson: "Ignoring predictable demand cycles ties up cash in inventory that isn't moving — seasonality is a planning problem."),
                ScenarioChoice(title: "Run a seasonal promotion", detail: "$100", cashDelta: -100, customerDelta: 2, priceDelta: 0, teamDelta: 0, resultSummary: "Softened the seasonal dip, though it didn't fully offset it.", lesson: "Smart businesses plan for predictable slow periods in advance instead of reacting after sales already dropped.")
            ]
        )
    ]
}

struct Scenario: Identifiable {
    var id: String
    let lessonTitle: String
    let prompt: String
    let choices: [ScenarioChoice]
}

struct ScenarioChoice: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let cashDelta: Double
    let customerDelta: Int
    let priceDelta: Double
    let teamDelta: Int
    let resultSummary: String
    let lesson: String
}

struct PlayerProfile: Codable {
    var name: String = "Player"
}
