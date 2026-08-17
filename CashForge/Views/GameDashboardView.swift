import SwiftUI

struct GameDashboardView: View {
    @EnvironmentObject var store: AppStore
    @State private var showScenario = false
    @State private var scenarioResult: ScenarioResult?
    @State private var showBankruptAlert = false
    @State private var scenarioResolved = false
    @State private var showLevelUp = false
    @State private var leveledUpTo = 0
    @State private var pendingEvent: MarketEvent?
    @State private var showBudgetSheet = false
    @Environment(\.colorScheme) var colorScheme

    private var business: BusinessState { store.business }

    var body: some View {
        if !business.hasStarted {
            BusinessStartView()
        } else {
            content
        }
    }

    private var content: some View {
        ZStack {
            Theme.background(colorScheme).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    header
                    statsGrid
                    advisorCard
                    budgetCard

                    if let scenario = store.currentScenario {
                        lessonCard(scenario)
                    }

                    Button("Next Month →") {
                        let levelBefore = business.level
                        let result = store.advanceMonth()
                        scenarioResolved = false
                        pendingEvent = result.event
                        if store.business.isBankrupt {
                            showBankruptAlert = true
                        } else if store.business.level > levelBefore {
                            leveledUpTo = store.business.level
                            showLevelUp = true
                        } else {
                            monthResultText = result.narrative
                            showMonthResult = true
                        }
                    }
                    .buttonStyle(GreenButtonStyle())
                    .disabled(!scenarioResolved)
                    .opacity(scenarioResolved ? 1 : 0.4)
                    .padding(.horizontal)

                    NavigationLink("View Lessons Applied") {
                        LessonsAppliedView()
                    }
                    .foregroundColor(Theme.gold(colorScheme))
                    .padding(.top, 4)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle("Business Simulation")
        .sheet(isPresented: $showScenario) {
            if let scenario = store.currentScenario {
                ScenarioSheet(scenario: scenario) { choice in
                    scenarioResult = store.resolveScenario(choice)
                    scenarioResolved = true
                }
                .environmentObject(store)
                .presentationDetents([.large])
                .interactiveDismissDisabled()
            }
        }
        .sheet(item: Binding(
            get: { scenarioResult.map { IdentifiableResult(result: $0) } },
            set: { if $0 == nil { scenarioResult = nil } }
        )) { wrapped in
            ScenarioResultView(result: wrapped.result) { scenarioResult = nil }
                .presentationDetents([.medium])
        }
        .alert("Month \(business.month - 1) Results", isPresented: $showMonthResult) {
            Button("Continue") {}
        } message: {
            Text(monthResultText + eventSuffix)
        }
        .sheet(isPresented: $showLevelUp) {
            LevelUpView(level: leveledUpTo, event: pendingEvent) { showLevelUp = false }
                .presentationDetents([.medium])
        }
        .alert("You're out of cash", isPresented: $showBankruptAlert) {
            if !business.hasUsedBailout {
                Button("Take Emergency Loan ($100)") {
                    store.acceptBailout()
                }
            }
            Button("Start Over", role: .destructive) {
                store.business.hasStarted = false
            }
        } message: {
            Text(bankruptcyExplanation + (business.hasUsedBailout ? "" : "\n\nYou can take a one-time emergency loan to keep going instead of starting over."))
        }
    }

    @State private var showMonthResult = false
    @State private var monthResultText = ""

    private var header: some View {
        VStack(spacing: 4) {
            Text(business.businessType?.rawValue ?? business.name)
                .font(.subheadline)
                .foregroundColor(.gray)
            Text("$\(Int(business.cash))")
                .font(.system(size: 44, weight: .bold))
                .foregroundColor(business.cash < 0 ? Theme.danger : Theme.gold(colorScheme))
            Text("Month \(business.month) · Level \(business.level)")
                .font(.caption)
                .foregroundColor(Theme.success)
        }
        .padding(.top)
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(title: "Customers", value: "\(business.customers)", icon: "person.2.fill")
            StatCard(title: "Price / Customer", value: "$\(Int(business.pricePerCustomer))", icon: "tag.fill")
            StatCard(title: "Team Size", value: "\(business.teamSize)", icon: "person.3.fill")
            StatCard(title: "Last Month Profit", value: "$\(Int(business.lastMonthProfit))", icon: "chart.line.uptrend.xyaxis")
        }
        .padding(.horizontal)
    }

    private var advisorCard: some View {
        let advice = AdvisorEngine.advice(for: business)
        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: advice.icon)
                .foregroundColor(Theme.gold(colorScheme))
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text("Advisor")
                    .font(.caption.bold())
                    .foregroundColor(Theme.gold(colorScheme))
                Text(advice.text)
                    .font(.subheadline)
                    .foregroundColor(Theme.text(colorScheme))
            }
        }
        .padding()
        .background(Theme.card(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
        .padding(.horizontal)
    }

    private var budgetCard: some View {
        Button {
            showBudgetSheet = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(Theme.gold(colorScheme))
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Invest This Month's Cash")
                        .font(.subheadline.bold())
                        .foregroundColor(Theme.text(colorScheme))
                    Text("Put cash toward marketing, product, or team")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Theme.card(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .sheet(isPresented: $showBudgetSheet) {
            BudgetAllocationSheet()
                .environmentObject(store)
                .presentationDetents([.medium])
        }
    }

    private func lessonCard(_ scenario: Scenario) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Month You'll Learn")
                .font(.caption.bold())
                .foregroundColor(Theme.gold(colorScheme))
            Text(scenario.lessonTitle)
                .font(.title3.bold())
                .foregroundColor(Theme.text(colorScheme))

            if scenarioResolved {
                Label("Decision made — advance to next month.", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(Theme.success)
            } else {
                Button("Face This Month's Decision") {
                    showScenario = true
                }
                .buttonStyle(GreenButtonStyle())
            }
        }
        .padding()
        .background(Theme.card(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
        .padding(.horizontal)
    }

    private var eventSuffix: String {
        guard let event = pendingEvent else { return "" }
        return "\n\n📰 \(event.title): \(event.description)"
    }

    private var bankruptcyExplanation: String {
        var reasons: [String] = []
        if business.teamSize > 0 && business.customers < business.teamSize * 3 {
            reasons.append("your team (\(business.teamSize) people) was too big for only \(business.customers) customers")
        }
        if business.lastMonthExpenses > business.lastMonthRevenue {
            reasons.append("your expenses ($\(Int(business.lastMonthExpenses))) outpaced your revenue ($\(Int(business.lastMonthRevenue)))")
        }
        let reasonText = reasons.isEmpty
            ? "You spent faster than your business could earn."
            : "Here's what went wrong: " + reasons.joined(separator: ", and ") + "."
        return "Your business ran out of money after \(business.month - 1) months. \(reasonText) Time to start a new business with the lessons you've learned."
    }
}

struct IdentifiableResult: Identifiable {
    let id = UUID()
    let result: ScenarioResult
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).foregroundColor(Theme.gold(colorScheme))
            Text(value).font(.title3.bold()).foregroundColor(Theme.text(colorScheme))
            Text(title).font(.caption).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Theme.card(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
    }
}

struct ScenarioSheet: View {
    let scenario: Scenario
    let onChoose: (ScenarioChoice) -> Void
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(scenario.lessonTitle, systemImage: "graduationcap.fill")
                            .font(.caption.bold())
                            .foregroundColor(Theme.gold(colorScheme))
                        Text(scenario.prompt)
                            .font(.title3.bold())
                            .foregroundColor(Theme.text(colorScheme))
                    }

                    VStack(spacing: 12) {
                        ForEach(Array(scenario.choices.enumerated()), id: \.element.id) { index, choice in
                            Button {
                                onChoose(choice)
                                dismiss()
                            } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    Text(letter(for: index))
                                        .font(.headline.bold())
                                        .foregroundColor(.black)
                                        .frame(width: 28, height: 28)
                                        .background(Theme.gold(colorScheme))
                                        .clipShape(Circle())
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(choice.title).font(.headline).foregroundColor(Theme.text(colorScheme))
                                        Text(choice.detail).font(.caption).foregroundColor(.gray)
                                    }
                                    Spacer()
                                }
                                .padding()
                                .background(Theme.card(colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Theme.background(colorScheme).ignoresSafeArea())
        }
    }

    private func letter(for index: Int) -> String {
        ["A", "B", "C", "D"][min(index, 3)]
    }
}

struct ScenarioResultView: View {
    let result: ScenarioResult
    let onDismiss: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Theme.success)
                        .padding(.top, 24)

                    VStack(spacing: 8) {
                        Text("Result")
                            .font(.caption.bold())
                            .foregroundColor(Theme.gold(colorScheme))
                        Text(result.summary)
                            .font(.headline)
                            .foregroundColor(Theme.text(colorScheme))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Takeaway", systemImage: "lightbulb.fill")
                            .font(.caption.bold())
                            .foregroundColor(Theme.gold(colorScheme))
                        Text(result.lesson)
                            .font(.subheadline)
                            .foregroundColor(Theme.text(colorScheme))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Theme.card(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
                    .padding(.horizontal)
                }
                .padding(.bottom, 16)
            }

            Button("Continue") { onDismiss() }
                .buttonStyle(GoldButtonStyle())
                .padding(.horizontal)
                .padding(.bottom, 24)
                .padding(.top, 12)
        }
        .background(Theme.background(colorScheme).ignoresSafeArea())
    }
}

struct BudgetAllocationSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedCategory: BudgetCategory = .marketing
    @State private var amountText: String = ""

    private var business: BusinessState { store.business }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Available cash: $\(Int(business.cash))")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.horizontal)

                    VStack(spacing: 10) {
                        ForEach(BudgetCategory.allCases) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: category.icon)
                                        .foregroundColor(Theme.gold(colorScheme))
                                        .frame(width: 28)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(category.rawValue)
                                            .font(.headline)
                                            .foregroundColor(Theme.text(colorScheme))
                                        Text(category.explanation)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                }
                                .padding()
                                .background(Theme.card(colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.cardRadius)
                                        .stroke(selectedCategory == category ? Theme.gold(colorScheme) : Color.clear, lineWidth: 2)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Amount to spend")
                            .font(.caption.bold())
                            .foregroundColor(Theme.gold(colorScheme))
                        TextField("$0", text: $amountText)
                            .keyboardType(.numberPad)
                            .padding()
                            .background(Theme.card(colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
                            .foregroundColor(Theme.text(colorScheme))
                    }
                    .padding(.horizontal)

                    Button("Invest") {
                        guard let amount = Double(amountText) else { return }
                        if store.allocateBudget(selectedCategory, amount: amount) {
                            dismiss()
                        }
                    }
                    .buttonStyle(GreenButtonStyle())
                    .disabled((Double(amountText) ?? 0) <= 0 || (Double(amountText) ?? 0) > business.cash)
                    .opacity((Double(amountText) ?? 0) <= 0 || (Double(amountText) ?? 0) > business.cash ? 0.4 : 1)
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
                .padding(.top)
            }
            .background(Theme.background(colorScheme).ignoresSafeArea())
            .navigationTitle("Invest Cash")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct LevelUpView: View {
    let level: Int
    let event: MarketEvent?
    let onDismiss: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @State private var animateIn = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "star.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(Theme.gold(colorScheme))
                .scaleEffect(animateIn ? 1 : 0.4)
                .opacity(animateIn ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: animateIn)

            VStack(spacing: 8) {
                Text("Level Up!")
                    .font(.largeTitle.bold())
                    .foregroundColor(Theme.text(colorScheme))
                Text("Your business reached Level \(level)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            if let event {
                VStack(spacing: 4) {
                    Text("📰 \(event.title)")
                        .font(.caption.bold())
                        .foregroundColor(Theme.gold(colorScheme))
                    Text(event.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
            }

            Spacer()

            Button("Continue") { onDismiss() }
                .buttonStyle(GoldButtonStyle())
                .padding(.horizontal)
                .padding(.bottom, 24)
        }
        .background(Theme.background(colorScheme).ignoresSafeArea())
        .onAppear { animateIn = true }
    }
}

struct LessonsAppliedView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        List {
            if store.business.appliedLessons.isEmpty {
                Text("No lessons applied yet. Unlock a summary and start the simulation.")
                    .foregroundColor(.gray)
            }
            ForEach(store.business.appliedLessons, id: \.self) { lesson in
                Label(lesson, systemImage: "checkmark.seal.fill")
                    .foregroundColor(Theme.gold(colorScheme))
            }
        }
        .navigationTitle("Lessons Applied")
        .scrollContentBackground(.hidden)
        .background(Theme.background(colorScheme))
    }
}
