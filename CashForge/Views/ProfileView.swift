import SwiftUI
import PhotosUI
import GameKit

struct ProfileView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var authService: AuthService
    @State private var showSettings = false
    @State private var showLeaderboard = false
    @State private var photoItem: PhotosPickerItem?
    @State private var avatarImage: Image?
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var appThemeRaw: String = AppTheme.dark.rawValue
    private var appTheme: AppTheme { AppTheme(rawValue: appThemeRaw) ?? .dark }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background(colorScheme).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 8) {
                            PhotosPicker(selection: $photoItem, matching: .images) {
                                ZStack {
                                    if let avatarImage {
                                        avatarImage
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 72, height: 72)
                                            .clipShape(Circle())
                                    } else {
                                        Circle()
                                            .fill(Theme.gold(colorScheme))
                                            .frame(width: 72, height: 72)
                                        Text(initials)
                                            .font(.title2.bold())
                                            .foregroundColor(Theme.background(colorScheme))
                                    }
                                    Image(systemName: "camera.fill")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                        .padding(6)
                                        .background(Circle().fill(Color.black.opacity(0.6)))
                                        .offset(x: 26, y: 26)
                                }
                            }
                            .onChange(of: photoItem) { newItem in
                                Task { await loadAvatar(from: newItem) }
                            }
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

                        if store.playerProfile.currentStreak > 1 {
                            HStack(spacing: 6) {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.orange)
                                Text("\(store.playerProfile.currentStreak) day streak")
                                    .font(.subheadline.bold())
                                    .foregroundColor(Theme.text(colorScheme))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Theme.card(colorScheme))
                            .clipShape(Capsule())
                        }

                        VStack(spacing: 12) {
                            InfoRow(label: "Highest Business Level", value: "\(store.business.level)")
                            InfoRow(label: "Cash Earned", value: "$\(Int(store.business.cash))")
                            InfoRow(label: "Summaries Unlocked", value: "\(store.videos.filter { $0.isUnlocked }.count)")

                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Progress to Level \(store.business.level + 1)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("\(Int(levelProgress * 100))%")
                                        .font(.caption.bold())
                                        .foregroundColor(Theme.gold(colorScheme))
                                }
                                ProgressView(value: levelProgress)
                                    .tint(Theme.gold(colorScheme))
                            }
                            .padding(.top, 4)
                        }
                        .padding()
                        .background(Theme.card(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
                        .padding(.horizontal)

                        Button {
                            showLeaderboard = true
                        } label: {
                            Label("View Leaderboard", systemImage: "trophy.fill")
                        }
                        .buttonStyle(GoldButtonStyle(outline: true))
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
                    .preferredColorScheme(appTheme.colorScheme)
            }
            .onAppear(perform: loadStoredAvatar)
            .sheet(isPresented: $showLeaderboard) {
                GameCenterLeaderboardView()
            }
        }
    }

    private var avatarFileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("profile_avatar.jpg")
    }

    private func loadStoredAvatar() {
        guard avatarImage == nil,
              let data = try? Data(contentsOf: avatarFileURL),
              let uiImage = UIImage(data: data) else { return }
        avatarImage = Image(uiImage: uiImage)
    }

    private func loadAvatar(from item: PhotosPickerItem?) async {
        guard let item, let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else { return }
        try? data.write(to: avatarFileURL)
        await MainActor.run {
            avatarImage = Image(uiImage: uiImage)
        }
    }

    private var displayName: String {
        if let name = authService.personalInfo?.fullName, !name.isEmpty {
            return name
        }
        return "Player"
    }

    private var initials: String {
        let parts = displayName.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return letters.isEmpty ? "?" : String(letters).uppercased()
    }

    private var levelProgress: Double {
        let target = Double(store.business.level) * 1000
        guard target > 0 else { return 0 }
        return min(max(store.business.lastMonthRevenue / target, 0), 1)
    }

    private func hasContactDetails(_ info: PersonalInfo) -> Bool {
        !info.phoneNumber.isEmpty || !info.addressLine.isEmpty || !info.city.isEmpty || !info.country.isEmpty
    }
}

struct GameCenterLeaderboardView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> GKGameCenterViewController {
        let controller = GKGameCenterViewController(
            leaderboardID: GameCenterService.cashEarnedLeaderboardID,
            playerScope: .global,
            timeScope: .allTime
        )
        controller.gameCenterDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: GKGameCenterViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, GKGameCenterControllerDelegate {
        func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
            gameCenterViewController.dismiss(animated: true)
        }
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
