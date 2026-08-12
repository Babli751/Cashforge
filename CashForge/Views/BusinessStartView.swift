import SwiftUI

struct BusinessStartView: View {
    @EnvironmentObject var store: AppStore
    @State private var selected: BusinessType?
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            Theme.background(colorScheme).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("How will you make your first money?")
                            .font(.title2.bold())
                            .foregroundColor(Theme.text(colorScheme))
                        Text("Every business starts differently. Pick a path — you can always start over later.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)

                    VStack(spacing: 12) {
                        ForEach(BusinessType.allCases) { type in
                            Button {
                                selected = type
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: type.icon)
                                        .font(.title2)
                                        .foregroundColor(Theme.gold(colorScheme))
                                        .frame(width: 36)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(type.rawValue)
                                            .font(.headline)
                                            .foregroundColor(Theme.text(colorScheme))
                                        Text(type.subtitle)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text(type.startingCash > 0 ? "Start with $\(Int(type.startingCash))" : "Start with $0 — no upfront cost")
                                            .font(.caption.bold())
                                            .foregroundColor(Theme.success)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Theme.card(colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.cardRadius)
                                        .stroke(selected == type ? Theme.gold(colorScheme) : Color.clear, lineWidth: 2)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)

                    if let selected {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Your First Step", systemImage: "lightbulb.fill")
                                .font(.subheadline.bold())
                                .foregroundColor(Theme.gold(colorScheme))
                            Text(selected.firstStepAdvice)
                                .font(.subheadline)
                                .foregroundColor(Theme.text(colorScheme))
                        }
                        .padding()
                        .background(Theme.card(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 20)

                    Button("Start This Business →") {
                        guard let selected else { return }
                        store.startBusiness(selected)
                    }
                    .buttonStyle(GreenButtonStyle())
                    .disabled(selected == nil)
                    .opacity(selected == nil ? 0.5 : 1)
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle("Business Simulation")
    }
}
