import SwiftUI

struct RootTabView: View {
    @StateObject private var store = AppStore()
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        TabView(selection: $store.selectedTab) {
            HomeFeedView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)

            MySummariesView()
                .tabItem { Label("My Summaries", systemImage: "doc.text.fill") }
                .tag(1)

            NavigationStack {
                GameDashboardView()
            }
            .tabItem { Label("Game", systemImage: "chart.bar.fill") }
            .tag(2)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(3)
        }
        .tint(Theme.gold(colorScheme))
        .environmentObject(store)
        .environmentObject(store.authService)
    }
}
