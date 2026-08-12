import SwiftUI

struct GameDashboardView: View {
    @EnvironmentObject var store: AppStore
    @State private var showScenario = false
    @State private var scenarioResult: ScenarioResult?
    @State private var showBankruptAlert = false
    @State private var scenarioResolved = false
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

                    if let scenario = store.currentScenario {
                        lessonCard(scenario)
                    }

                    Button("Next Month →") {
                        let narrative = store.advanceMonth()
                        scenarioResolved = false
                        if store.business.isBankrupt {
                            showBankruptAlert = true
                        } else {
                            monthResultText = narrative
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
            Text(monthResultText)
        }
        .alert("You're out of cash", isPresented: $showBankruptAlert) {
            Button("Start Over", role: .destructive) {
                store.business.hasStarted = false
            }
        } message: {
            Text(bankruptcyExplanation)
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
