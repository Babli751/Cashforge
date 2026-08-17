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
    var hasUsedBailout: Bool = false
    var history: [MonthRecord] = []

    /// Cumulative effect of past budget allocations — persists month to month rather
    /// than resetting, representing durable brand/product/ops improvements.
    var marketingBoost: Double = 0
    var productQualityBoost: Double = 0
    var opsCapacityBoost: Double = 0

    static let salaryPerHire: Double = 150
    static let fixedMonthlyCost: Double = 50

    var projectedRevenue: Double {
        Double(customers) * pricePerCustomer
    }

    /// Team costs are reduced by ops capacity investment — better processes mean
    /// each hire goes further, up to a 40% max discount.
    var projectedExpenses: Double {
        let opsDiscount = min(opsCapacityBoost * 0.02, 0.4)
        return Double(teamSize) * Self.salaryPerHire * (1 - opsDiscount) + Self.fixedMonthlyCost
    }

    var projectedProfit: Double {
        projectedRevenue - projectedExpenses
    }
}

enum BudgetCategory: String, CaseIterable, Identifiable {
    case marketing = "Marketing"
    case product = "Product"
    case team = "Team"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .marketing: return "megaphone.fill"
        case .product: return "star.fill"
        case .team: return "person.3.fill"
        }
    }

    var explanation: String {
        switch self {
        case .marketing: return "Attracts new customers. Returns shrink the more you spend in one month."
        case .product: return "Improves quality — reduces customer churn over time."
        case .team: return "Adds operational capacity — helps you serve more customers without quality dropping."
        }
    }
}

struct MarketEvent {
    let title: String
    let description: String
    let cashDelta: Double
    let customerDelta: Int

    static let all: [MarketEvent] = [
        MarketEvent(title: "Viral Mention", description: "Someone with a big following mentioned your business online.", cashDelta: 0, customerDelta: 8),
        MarketEvent(title: "Payment Processor Outage", description: "A day-long outage meant some customers couldn't check out.", cashDelta: -80, customerDelta: -2),
        MarketEvent(title: "Local Economic Dip", description: "Spending in your market slowed down this month.", cashDelta: 0, customerDelta: -4),
        MarketEvent(title: "Unexpected Tax Bill", description: "A quarterly tax payment came due.", cashDelta: -120, customerDelta: 0),
        MarketEvent(title: "Referral Wave", description: "Happy customers referred several friends without being asked.", cashDelta: 0, customerDelta: 5),
        MarketEvent(title: "Supplier Price Hike", description: "A key supplier raised prices with no notice.", cashDelta: -60, customerDelta: 0)
    ]
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
    case contentCreation = "Content Creation"
    case localService = "Local Service Business"
    case saas = "Subscription Software"
    case dropshipping = "Dropshipping"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .app: return "Build something once, sell it to many people."
        case .freelance: return "Sell your time and skills directly to clients."
        case .reselling: return "Buy low, sell high — physical or digital products."
        case .contentCreation: return "Build an audience, sell attention to sponsors."
        case .localService: return "Serve customers in person — capacity is physical, not digital."
        case .saas: return "Recurring subscriptions — revenue you have to keep earning every month."
        case .dropshipping: return "Sell products you never touch — a supplier ships directly to customers."
        }
    }

    var icon: String {
        switch self {
        case .app: return "iphone"
        case .freelance: return "person.fill.checkmark"
        case .reselling: return "shippingbox.fill"
        case .contentCreation: return "video.fill"
        case .localService: return "storefront.fill"
        case .saas: return "arrow.triangle.2.circlepath"
        case .dropshipping: return "shippingbox.and.arrow.backward.fill"
        }
    }

    /// Starting conditions: how you earn your first $500 before "real" business stats kick in.
    var startingCash: Double {
        switch self {
        case .app: return 200
        case .freelance: return 0
        case .reselling: return 300
        case .contentCreation: return 0
        case .localService: return 250
        case .saas: return 150
        case .dropshipping: return 100
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
        case .contentCreation:
            return "You start with $0 and no audience. Growth is slow at first — consistency matters more than any single post."
        case .localService:
            return "You have $250 for basic equipment. Unlike digital businesses, you're capped by hours in a day and people in your area."
        case .saas:
            return "You have $150 for basic hosting. Every subscriber you lose this month has to be replaced just to stay flat — churn is the enemy."
        case .dropshipping:
            return "You have $100 for ads — no inventory to buy since your supplier ships directly. Low startup cost, but you don't control fulfillment quality."
        }
    }

    var scenarios: [Scenario] {
        switch self {
        case .app: return Self.appScenarios
        case .freelance: return Self.freelanceScenarios
        case .reselling: return Self.resellingScenarios
        case .contentCreation: return Self.contentCreationScenarios
        case .localService: return Self.localServiceScenarios
        case .saas: return Self.saasScenarios
        case .dropshipping: return Self.dropshippingScenarios
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

    private static let contentCreationScenarios: [Scenario] = [
        Scenario(
            id: "content_consistency",
            lessonTitle: "Consistency Compounds",
            prompt: "You've missed your posting schedule twice this month — life got busy.",
            choices: [
                ScenarioChoice(title: "Skip until you feel inspired", detail: "No cost", cashDelta: 0, customerDelta: -5, priceDelta: 0, teamDelta: 0, resultSummary: "The algorithm deprioritized your content, views dropped noticeably.", lesson: "Platforms reward consistency, not just quality — an irregular schedule quietly kills reach even if each piece is good."),
                ScenarioChoice(title: "Batch-produce content in advance", detail: "$50 for editing help", cashDelta: -50, customerDelta: 6, priceDelta: 0, teamDelta: 0, resultSummary: "Having a buffer meant you never missed a post, growth stayed steady.", lesson: "Batching content removes 'do I feel like it today' from the equation — consistency becomes a system, not willpower.")
            ]
        ),
        Scenario(
            id: "content_sponsor_fit",
            lessonTitle: "Audience Trust Is the Asset",
            prompt: "A sponsor offers good money to promote a product that doesn't really fit your audience.",
            choices: [
                ScenarioChoice(title: "Take the deal anyway", detail: "+$200", cashDelta: 200, customerDelta: -6, priceDelta: 0, teamDelta: 0, resultSummary: "Made quick cash, but comments were skeptical and some followers left.", lesson: "Your audience's trust is the actual product you're selling to sponsors — a bad-fit promotion spends down trust for short-term cash."),
                ScenarioChoice(title: "Turn it down", detail: "No cost", cashDelta: 0, customerDelta: 2, priceDelta: 0, teamDelta: 0, resultSummary: "Passed on the money, but the audience noticed you're selective about promotions.", lesson: "Saying no to bad-fit sponsorships protects the long-term value of your audience — trust compounds, quick cash doesn't.")
            ]
        ),
        Scenario(
            id: "content_platform_risk",
            lessonTitle: "Platform Dependency",
            prompt: "Almost all your audience is on one platform, and it just changed its algorithm — your reach dropped overnight.",
            choices: [
                ScenarioChoice(title: "Wait for the algorithm to stabilize", detail: "No cost", cashDelta: 0, customerDelta: -6, priceDelta: 0, teamDelta: 0, resultSummary: "Reach stayed suppressed for weeks with no real control over it.", lesson: "Building entirely on one platform means someone else's business decisions can wreck your income overnight — you don't own that audience."),
                ScenarioChoice(title: "Start building an email list / second platform", detail: "$100", cashDelta: -100, customerDelta: 3, priceDelta: 0, teamDelta: 0, resultSummary: "Slower growth short-term, but now you have a channel algorithms can't take away.", lesson: "Owning your audience (email list, direct channel) is protection against platform risk — rented attention can vanish with one policy change.")
            ]
        ),
        Scenario(
            id: "content_viral_spike",
            lessonTitle: "Capturing a Spike",
            prompt: "One of your posts went unexpectedly viral, bringing a wave of new followers.",
            choices: [
                ScenarioChoice(title: "Just enjoy the view count", detail: "No cost", cashDelta: 0, customerDelta: 4, priceDelta: 0, teamDelta: 0, resultSummary: "Most of the new attention faded without converting to anything lasting.", lesson: "Viral moments are traffic, not an asset — without a way to capture it (offer, list, follow prompt), most of it evaporates."),
                ScenarioChoice(title: "Add a clear call-to-action to convert viewers", detail: "No cost", cashDelta: 0, customerDelta: 10, priceDelta: 0, teamDelta: 0, resultSummary: "Turned a big share of the temporary spike into real followers.", lesson: "A viral spike is a rare chance to convert strangers into an audience — but only if you give them an obvious next step.")
            ]
        ),
        Scenario(
            id: "content_niche_vs_broad",
            lessonTitle: "Niche Audiences Monetize Better",
            prompt: "You could broaden your content to appeal to more people, or go deeper into your specific niche.",
            choices: [
                ScenarioChoice(title: "Broaden the content", detail: "No cost", cashDelta: 0, customerDelta: 6, priceDelta: -3, teamDelta: 0, resultSummary: "Reached more people, but sponsors were less interested — broad audiences are harder to target.", lesson: "Broad audiences get more views but are worth less to advertisers — reach and monetization value aren't the same thing."),
                ScenarioChoice(title: "Go deeper into the niche", detail: "No cost", cashDelta: 0, customerDelta: 2, priceDelta: 8, teamDelta: 0, resultSummary: "Fewer new followers, but the ones you have are highly engaged — sponsors paid a premium.", lesson: "A specific, engaged niche audience is often more valuable to monetize than a large generic one — advertisers pay for relevance.")
            ]
        ),
        Scenario(
            id: "content_burnout",
            lessonTitle: "Sustainable Output",
            prompt: "You've been posting daily for months and the pace is becoming exhausting.",
            choices: [
                ScenarioChoice(title: "Push through at the same pace", detail: "No cost", cashDelta: 0, customerDelta: -4, priceDelta: 0, teamDelta: 0, resultSummary: "Content quality started slipping as fatigue set in, and it showed.", lesson: "An unsustainable pace eventually shows up in the work itself — burnout is a business risk, not just a personal one."),
                ScenarioChoice(title: "Bring on editing help, reduce your workload", detail: "Adds team member", cashDelta: 0, customerDelta: 3, priceDelta: 0, teamDelta: 1, resultSummary: "Delegating the repetitive work let you keep the pace up without burning out.", lesson: "Even solo creators hit a ceiling on personal output — delegating the mechanical parts protects both quality and longevity.")
            ]
        ),
        Scenario(
            id: "content_diversify_income",
            lessonTitle: "Income Diversification",
            prompt: "Right now, sponsorships are your only source of income. A sponsor's budget cuts would leave you with nothing.",
            choices: [
                ScenarioChoice(title: "Stay focused on sponsorships only", detail: "No cost", cashDelta: 0, customerDelta: 0, priceDelta: 0, teamDelta: 0, resultSummary: "Simple to manage, but your income depends entirely on other companies' ad budgets.", lesson: "Relying on a single income source (even a good one) leaves you exposed — sponsors can cut budgets any time, for reasons that have nothing to do with you."),
                ScenarioChoice(title: "Launch your own small product", detail: "$150 setup cost", cashDelta: -150, customerDelta: 2, priceDelta: 5, teamDelta: 0, resultSummary: "Built a second income stream you control directly, independent of any sponsor.", lesson: "Owning a product alongside sponsorship income diversifies risk — you're not entirely at the mercy of someone else's marketing budget.")
            ]
        )
    ]

    private static let localServiceScenarios: [Scenario] = [
        Scenario(
            id: "local_capacity_ceiling",
            lessonTitle: "The Physical Capacity Ceiling",
            prompt: "You're fully booked every day this month and still turning away customers.",
            choices: [
                ScenarioChoice(title: "Keep turning people away", detail: "No cost", cashDelta: 0, customerDelta: -3, priceDelta: 0, teamDelta: 0, resultSummary: "Lost potential customers to competitors who had availability.", lesson: "Unlike digital products, a local service has a hard capacity ceiling — hours in a day and hands available. Demand above that ceiling is just lost."),
                ScenarioChoice(title: "Hire another person to add capacity", detail: "Adds team member", cashDelta: 0, customerDelta: 8, priceDelta: 0, teamDelta: 1, resultSummary: "New capacity let you serve the extra demand instead of turning it away.", lesson: "Growing past your personal capacity ceiling requires adding people — this is the fundamental scaling problem of service businesses.")
            ]
        ),
        Scenario(
            id: "local_no_shows",
            lessonTitle: "The Cost of No-Shows",
            prompt: "Customers keep booking appointments and not showing up, leaving you with unpaid idle time.",
            choices: [
                ScenarioChoice(title: "Do nothing about it", detail: "No cost", cashDelta: -60, customerDelta: 0, priceDelta: 0, teamDelta: 0, resultSummary: "Lost revenue from empty slots that could have gone to other customers.", lesson: "In a business selling time, no-shows are a direct and often invisible cost — every empty slot was revenue you could have earned elsewhere."),
                ScenarioChoice(title: "Require a deposit to book", detail: "No cost", cashDelta: 0, customerDelta: -2, priceDelta: 0, teamDelta: 0, resultSummary: "Fewer no-shows, though a few price-sensitive customers went elsewhere.", lesson: "A booking deposit filters out low-commitment customers and protects your time — a small tradeoff in volume for reliability.")
            ]
        ),
        Scenario(
            id: "local_location",
            lessonTitle: "Location Is a Cost and an Asset",
            prompt: "A prime location nearby has opened up, at double your current rent.",
            choices: [
                ScenarioChoice(title: "Stay where you are", detail: "No cost", cashDelta: 0, customerDelta: 0, priceDelta: 0, teamDelta: 0, resultSummary: "Kept costs stable, but foot traffic stayed the same too.", lesson: "Location is a fixed cost that directly caps your walk-in demand — staying put is safe but also limits organic growth."),
                ScenarioChoice(title: "Move to the prime location", detail: "$200 moving cost, higher rent", cashDelta: -200, customerDelta: 7, priceDelta: 0, teamDelta: 0, resultSummary: "Foot traffic increased significantly, offsetting the higher rent.", lesson: "For local businesses, location is inventory — better foot traffic can be worth paying more for, if the math works out.")
            ]
        ),
        Scenario(
            id: "local_repeat_customers",
            lessonTitle: "Repeat Customers Are Cheaper Than New Ones",
            prompt: "You could spend on ads for new customers, or invest in getting existing customers to return more often.",
            choices: [
                ScenarioChoice(title: "Spend on ads for new customers", detail: "$120", cashDelta: -120, customerDelta: 5, priceDelta: 0, teamDelta: 0, resultSummary: "Got new customers, but at a real acquisition cost each time.", lesson: "Acquiring new local customers usually costs more than keeping existing ones coming back — ads work, but they're the expensive lever."),
                ScenarioChoice(title: "Start a simple loyalty/rewards system", detail: "$40 setup", cashDelta: -40, customerDelta: 3, priceDelta: 0, teamDelta: 0, resultSummary: "Existing customers started coming back more often, cheaply.", lesson: "For local businesses, repeat visits from existing customers are usually cheaper to generate than brand-new customers — loyalty compounds.")
            ]
        ),
        Scenario(
            id: "local_seasonality",
            lessonTitle: "Foot Traffic Isn't Constant",
            prompt: "You're heading into a historically slow season for foot traffic in your area.",
            choices: [
                ScenarioChoice(title: "Keep the same staffing and hours", detail: "No cost", cashDelta: 0, customerDelta: -5, priceDelta: 0, teamDelta: 0, resultSummary: "Paid full staff costs through a slow period with less revenue to cover it.", lesson: "Local demand often has a predictable seasonal rhythm — not adjusting for it means paying peak-season costs during a slow season."),
                ScenarioChoice(title: "Run a local promotion to smooth the dip", detail: "$80", cashDelta: -80, customerDelta: 3, priceDelta: 0, teamDelta: 0, resultSummary: "Softened the seasonal slowdown somewhat.", lesson: "Planning for predictable slow seasons in advance beats reacting after revenue already dropped.")
            ]
        ),
        Scenario(
            id: "local_skill_investment",
            lessonTitle: "Skill Is Part of the Product",
            prompt: "A training course could improve your team's skill level, but it costs money and time off the floor.",
            choices: [
                ScenarioChoice(title: "Skip it, keep working as-is", detail: "No cost", cashDelta: 0, customerDelta: -2, priceDelta: 0, teamDelta: 0, resultSummary: "A couple of customers mentioned inconsistent quality in reviews.", lesson: "In a service business, your team's skill level IS the product — under-investing in it shows up directly in customer experience."),
                ScenarioChoice(title: "Invest in the training", detail: "$90", cashDelta: -90, customerDelta: 4, priceDelta: 4, teamDelta: 0, resultSummary: "Service quality improved, and you could reasonably charge a bit more.", lesson: "Investing in team skill pays back through both better retention and pricing power — quality is a lever you can pull directly.")
            ]
        ),
        Scenario(
            id: "local_second_location",
            lessonTitle: "Replicating What Works",
            prompt: "Your location has been consistently profitable for months. You could open a second one.",
            choices: [
                ScenarioChoice(title: "Stay focused on one location", detail: "No cost", cashDelta: 0, customerDelta: 0, priceDelta: 0, teamDelta: 0, resultSummary: "Kept things simple and manageable, but revenue stayed capped by one location's ceiling.", lesson: "A single location has a hard revenue ceiling no matter how well it's run — staying put trades growth for simplicity."),
                ScenarioChoice(title: "Open a second location", detail: "$400 setup cost", cashDelta: -400, customerDelta: 10, priceDelta: 0, teamDelta: 2, resultSummary: "Took real capital and management effort, but roughly doubled your addressable customers.", lesson: "Once a location model is proven, replicating it is how service businesses scale past the physical ceiling of one site — but it multiplies risk and complexity too.")
            ]
        )
    ]

    private static let saasScenarios: [Scenario] = [
        Scenario(
            id: "saas_churn",
            lessonTitle: "Churn Is the Silent Killer",
            prompt: "A batch of subscribers cancelled this month. You could investigate why, or just focus on getting new sign-ups.",
            choices: [
                ScenarioChoice(title: "Focus purely on new sign-ups", detail: "$100 on ads", cashDelta: -100, customerDelta: 5, priceDelta: 0, teamDelta: 0, resultSummary: "Replaced the churned subscribers, but the underlying cancellation reason is still there.", lesson: "In subscription businesses, growth can mask churn — you can be adding customers and still be one leaky bucket away from stalling."),
                ScenarioChoice(title: "Investigate why they cancelled", detail: "$60 for user interviews", cashDelta: -60, customerDelta: 2, priceDelta: 0, teamDelta: 0, resultSummary: "Found a common complaint and fixed it, cancellations slowed.", lesson: "Fixing the reason people leave compounds — every month you don't fix it, it costs you subscribers again and again.")
            ]
        ),
        Scenario(
            id: "saas_onboarding",
            lessonTitle: "First Impressions Determine Retention",
            prompt: "Data shows many new subscribers cancel within their first week without ever using the core feature.",
            choices: [
                ScenarioChoice(title: "Leave onboarding as-is", detail: "No cost", cashDelta: 0, customerDelta: -4, priceDelta: 0, teamDelta: 0, resultSummary: "First-week cancellations continued at the same rate.", lesson: "If customers cancel before finding value, everything else about your product doesn't matter yet — day one experience decides a lot of your churn."),
                ScenarioChoice(title: "Build a simple onboarding walkthrough", detail: "$120", cashDelta: -120, customerDelta: 5, priceDelta: 0, teamDelta: 0, resultSummary: "More new subscribers reached the core feature and stuck around.", lesson: "Investing in onboarding pays back through retention — it's cheaper to help an existing sign-up succeed than to acquire a replacement one.")
            ]
        ),
        Scenario(
            id: "saas_feature_creep",
            lessonTitle: "Feature Creep Dilutes the Core Value",
            prompt: "A few vocal customers are requesting niche features that would take real development time.",
            choices: [
                ScenarioChoice(title: "Build everything requested", detail: "$150", cashDelta: -150, customerDelta: 2, priceDelta: 0, teamDelta: 0, resultSummary: "Made a few loud customers happy, but the product got more complex for everyone else.", lesson: "Saying yes to every feature request can dilute the core value that made people subscribe in the first place — not all feedback should become a feature."),
                ScenarioChoice(title: "Politely decline, stay focused", detail: "No cost", cashDelta: 0, customerDelta: -1, priceDelta: 0, teamDelta: 0, resultSummary: "Lost a couple of edge-case requests, but the product stayed simple and sharp.", lesson: "Product focus is a retention strategy — a simple tool that does one thing well often outperforms a bloated one trying to please everyone.")
            ]
        ),
        Scenario(
            id: "saas_free_tier",
            lessonTitle: "Free Tiers Are a Funnel, Not Charity",
            prompt: "You're considering adding a free tier to attract more sign-ups.",
            choices: [
                ScenarioChoice(title: "Skip it, paid-only", detail: "No cost", cashDelta: 0, customerDelta: 0, priceDelta: 0, teamDelta: 0, resultSummary: "Kept things simple, but lost potential sign-ups who wanted to try before paying.", lesson: "Without a low-friction way to try the product, you lose people who would've converted after experiencing the value first."),
                ScenarioChoice(title: "Launch a limited free tier", detail: "$50 infra cost", cashDelta: -50, customerDelta: 7, priceDelta: -2, teamDelta: 0, resultSummary: "Sign-ups increased and a meaningful share converted to paid over time.", lesson: "A free tier is a customer acquisition funnel, not generosity — it works when free users' cost is low and enough convert to paid.")
            ]
        ),
        Scenario(
            id: "saas_annual_plan",
            lessonTitle: "Annual Plans Trade Discount for Cashflow",
            prompt: "You could push customers toward annual billing with a discount, locking in cash upfront.",
            choices: [
                ScenarioChoice(title: "Keep monthly billing only", detail: "No cost", cashDelta: 0, customerDelta: 0, priceDelta: 0, teamDelta: 0, resultSummary: "Revenue stayed predictable but spread thin month to month.", lesson: "Monthly-only billing means you're always one cancellation away from losing that customer — there's no cash cushion."),
                ScenarioChoice(title: "Offer a discounted annual plan", detail: "No cost", cashDelta: 150, customerDelta: 0, priceDelta: -1, teamDelta: 0, resultSummary: "A chunk of customers switched to annual, giving you cash upfront at a slight discount.", lesson: "Annual plans trade a bit of revenue (the discount) for cashflow certainty and lower churn risk — a real business tradeoff, not free money.")
            ]
        ),
        Scenario(
            id: "saas_downtime",
            lessonTitle: "Reliability Is Table Stakes",
            prompt: "Your service had a few hours of downtime this month due to a server issue.",
            choices: [
                ScenarioChoice(title: "Fix it and move on quietly", detail: "$40", cashDelta: -40, customerDelta: -5, priceDelta: 0, teamDelta: 0, resultSummary: "Some subscribers who depend on the tool daily lost trust and cancelled.", lesson: "For software people pay monthly for, reliability isn't a feature — it's the baseline expectation. Downtime directly threatens retention."),
                ScenarioChoice(title: "Invest in better infrastructure", detail: "$180", cashDelta: -180, customerDelta: -1, priceDelta: 0, teamDelta: 0, resultSummary: "Cost more upfront, but greatly reduced the risk of it happening again.", lesson: "Paying for reliability upfront is cheaper than repeatedly losing subscribers to outages — infrastructure is retention infrastructure.")
            ]
        ),
        Scenario(
            id: "saas_expansion_revenue",
            lessonTitle: "Expansion Revenue Beats New Acquisition",
            prompt: "Your existing subscribers are using the product heavily — some might pay more for a higher tier.",
            choices: [
                ScenarioChoice(title: "Only focus on acquiring new subscribers", detail: "$100 on ads", cashDelta: -100, customerDelta: 4, priceDelta: 0, teamDelta: 0, resultSummary: "Got new subscribers at the usual acquisition cost.", lesson: "Chasing only new customers ignores revenue sitting inside your existing base — acquisition is usually the most expensive way to grow."),
                ScenarioChoice(title: "Launch a higher-priced tier for power users", detail: "$70 to build it", cashDelta: -70, customerDelta: 0, priceDelta: 6, teamDelta: 0, resultSummary: "A share of existing subscribers upgraded, raising revenue without any new acquisition cost.", lesson: "Expansion revenue — getting existing customers to pay more — is often cheaper and more reliable growth than acquiring new ones from scratch.")
            ]
        )
    ]

    private static let dropshippingScenarios: [Scenario] = [
        Scenario(
            id: "dropship_supplier_reliability",
            lessonTitle: "You Don't Control Fulfillment",
            prompt: "Your supplier has been shipping orders late, and customers are blaming you for it.",
            choices: [
                ScenarioChoice(title: "Keep using the same supplier", detail: "No cost", cashDelta: 0, customerDelta: -6, priceDelta: 0, teamDelta: 0, resultSummary: "Late shipments kept generating complaints under your brand name.", lesson: "In dropshipping, your supplier's problems become your reputation problems — you're liable for fulfillment quality you don't directly control."),
                ScenarioChoice(title: "Switch to a more reliable supplier", detail: "$70 to requalify", cashDelta: -70, customerDelta: 3, priceDelta: 0, teamDelta: 0, resultSummary: "Shipping times improved and complaints dropped.", lesson: "Supplier reliability is a core part of the product in dropshipping — it's worth paying to switch away from an unreliable one.")
            ]
        ),
        Scenario(
            id: "dropship_thin_margins",
            lessonTitle: "Thin Margins Leave No Room for Error",
            prompt: "After supplier cost and ad spend, your margin per sale is razor-thin.",
            choices: [
                ScenarioChoice(title: "Keep pushing volume at thin margin", detail: "No cost", cashDelta: 0, customerDelta: 3, priceDelta: 0, teamDelta: 0, resultSummary: "Sales grew, but profit barely moved — you're working hard for very little.", lesson: "Thin margins mean a small cost increase (ads, returns, supplier price) can wipe out your profit entirely — there's little buffer for mistakes."),
                ScenarioChoice(title: "Raise prices to build a real margin", detail: "No cost", cashDelta: 0, customerDelta: -2, priceDelta: 6, teamDelta: 0, resultSummary: "Lost a few price-sensitive buyers, but each remaining sale was actually profitable.", lesson: "A sustainable margin matters more than raw sales volume — selling more of something barely profitable doesn't build a real business.")
            ]
        ),
        Scenario(
            id: "dropship_ad_dependency",
            lessonTitle: "Rented Traffic",
            prompt: "Almost all your sales come directly from paid ads — when you pause spending, sales stop almost immediately.",
            choices: [
                ScenarioChoice(title: "Keep relying entirely on paid ads", detail: "$100", cashDelta: -100, customerDelta: 5, priceDelta: 0, teamDelta: 0, resultSummary: "Sales came in, but stopped the moment ad spend paused — no independent momentum.", lesson: "A business that only exists while ads are running doesn't have real customer demand of its own — it's renting attention, not earning it."),
                ScenarioChoice(title: "Invest in email capture and retargeting your own list", detail: "$60", cashDelta: -60, customerDelta: 2, priceDelta: 0, teamDelta: 0, resultSummary: "Built a small list of past buyers you can reach without paying for ads every time.", lesson: "Owning a way to reach past customers directly reduces dependence on rented ad traffic — it's the difference between a channel and an asset.")
            ]
        ),
        Scenario(
            id: "dropship_chargebacks",
            lessonTitle: "Trust Problems Show Up as Chargebacks",
            prompt: "Customers are disputing charges because the product looked different from the ad photos.",
            choices: [
                ScenarioChoice(title: "Keep using the flashy ad photos", detail: "No cost", cashDelta: -90, customerDelta: -3, priceDelta: 0, teamDelta: 0, resultSummary: "Chargebacks and refund requests kept eating into profit and reputation.", lesson: "Overselling a product with misleading marketing generates short-term clicks but long-term costs — chargebacks, refunds, and platform bans."),
                ScenarioChoice(title: "Use honest, accurate product photos", detail: "No cost", cashDelta: 0, customerDelta: -1, priceDelta: 0, teamDelta: 0, resultSummary: "Slightly lower click rate, but far fewer disputes and much better reviews.", lesson: "Setting accurate expectations reduces disputes and builds trust — conversion rate isn't the only number that matters.")
            ]
        ),
        Scenario(
            id: "dropship_product_testing",
            lessonTitle: "Fast, Cheap Product Testing",
            prompt: "You're not sure if a new product will sell. Dropshipping lets you test it without buying inventory upfront.",
            choices: [
                ScenarioChoice(title: "Skip testing, commit to one product long-term", detail: "No cost", cashDelta: 0, customerDelta: 0, priceDelta: 0, teamDelta: 0, resultSummary: "Missed the chance to find a better-selling product cheaply.", lesson: "Dropshipping's biggest advantage is low-risk product testing — not using that advantage wastes the one edge the model gives you over holding inventory."),
                ScenarioChoice(title: "Run small test ads for a few product ideas", detail: "$80", cashDelta: -80, customerDelta: 4, priceDelta: 0, teamDelta: 0, resultSummary: "Found which product actually resonated before committing further budget.", lesson: "Testing demand cheaply before scaling spend is exactly what dropshipping is good for — validate before you commit real budget.")
            ]
        ),
        Scenario(
            id: "dropship_brand_vs_generic",
            lessonTitle: "Anyone Can Sell the Same Product",
            prompt: "You're selling the exact same generic product as dozens of other stores.",
            choices: [
                ScenarioChoice(title: "Compete purely on price", detail: "Drop price by $4", cashDelta: 0, customerDelta: 3, priceDelta: -4, teamDelta: 0, resultSummary: "Won some price-sensitive sales, but margin shrank further.", lesson: "When you're selling an undifferentiated product, price is often the only lever left — and it's a race to the bottom against everyone else doing the same thing."),
                ScenarioChoice(title: "Build a distinct brand around the product", detail: "$130", cashDelta: -130, customerDelta: 2, priceDelta: 5, teamDelta: 0, resultSummary: "Customers started associating quality and trust with your store specifically, not just the product.", lesson: "Branding is how you escape competing on price alone when the underlying product is a commodity anyone can source.")
            ]
        ),
        Scenario(
            id: "dropship_scaling_ads",
            lessonTitle: "Scaling Ad Spend Isn't Linear",
            prompt: "Your ads are profitable at your current budget. You're considering spending much more to scale fast.",
            choices: [
                ScenarioChoice(title: "Triple the ad budget immediately", detail: "$300", cashDelta: -300, customerDelta: 6, priceDelta: 0, teamDelta: 0, resultSummary: "Cost per new customer rose sharply as you exhausted the easiest-to-reach buyers first.", lesson: "Ad performance rarely scales linearly — the first customers found are the cheapest, and pushing budget hard usually raises your cost per customer."),
                ScenarioChoice(title: "Scale the budget gradually", detail: "$120", cashDelta: -120, customerDelta: 4, priceDelta: 0, teamDelta: 0, resultSummary: "Grew steadily while keeping acquisition cost close to sustainable levels.", lesson: "Gradual scaling lets you catch rising acquisition costs before they blow up your margin — fast scaling trades control for speed.")
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
    var currentStreak: Int = 0
    var lastPlayedDate: Date?
}
