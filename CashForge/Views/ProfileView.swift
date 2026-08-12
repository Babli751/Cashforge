import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var authService: AuthService
    @State private var showSettings = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background(colorScheme).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 8) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 64))
                                .foregroundColor(Theme.gold(colorScheme))
                            Text(displayName)
                                .font(.title3.bold())
                                .foregroundColor(Theme.text(colorScheme))
                            if authService.isSignedIn {
                                Label("Signed in", systemImage: "checkmark.seal.fill")
                                    .font(.caption)
                                    .foregroundColor(Theme.success)
                            } else {
                                Text("Playing as guest")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.top)

                        VStack(spacing: 12) {
                            InfoRow(label: "Highest Business Level", value: "\(store.business.level)")
                            InfoRow(label: "Cash Earned", value: "$\(Int(store.business.cash))")
                            InfoRow(label: "Summaries Unlocked", value: "\(store.videos.filter { $0.isUnlocked }.count)")
                        }
                        .padding()
                        .background(Theme.card(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
                        .padding(.horizontal)

                        if let info = authService.personalInfo, hasContactDetails(info) {
                            VStack(spacing: 12) {
                                if !info.phoneNumber.isEmpty {
                                    InfoRow(label: "Phone", value: info.phoneNumber)
                                }
                                if !info.addressLine.isEmpty {
                                    InfoRow(label: "Address", value: info.addressLine)
                                }
                                if !info.city.isEmpty {
                                    InfoRow(label: "City", value: info.city)
                                }
                                if !info.country.isEmpty {
                                    InfoRow(label: "Country", value: info.country)
                                }
                            }
                            .padding()
                            .background(Theme.card(colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
                            .padding(.horizontal)
                        }

                        Text("Videos belong to School of Hard Knocks. Summaries & game are original content, not affiliated with or endorsed by School of Hard Knocks or Alex Hormozi.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(Theme.gold(colorScheme))
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(store)
                    .environmentObject(authService)
            }
        }
    }

    private var displayName: String {
        if let name = authService.personalInfo?.fullName, !name.isEmpty {
            return name
        }
        return "Player"
    }

    private func hasContactDetails(_ info: PersonalInfo) -> Bool {
        !info.phoneNumber.isEmpty || !info.addressLine.isEmpty || !info.city.isEmpty || !info.country.isEmpty
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        HStack {
            Text(label).foregroundColor(.gray)
            Spacer()
            Text(value).foregroundColor(Theme.text(colorScheme)).bold()
        }
    }
}
