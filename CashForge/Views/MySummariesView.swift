import SwiftUI

struct MySummariesView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var authService: AuthService
    @Environment(\.colorScheme) var colorScheme
    @State private var showAuthSheet = false

    var unlocked: [VideoItem] {
        store.videos.filter { $0.isUnlocked }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background(colorScheme).ignoresSafeArea()
                if !authService.isSignedIn {
                    VStack(spacing: 14) {
                        Image(systemName: "lock.doc")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("Sign in to see your summaries")
                            .foregroundColor(.gray)
                        Button("Sign In / Register") {
                            showAuthSheet = true
                        }
                        .buttonStyle(GoldButtonStyle())
                        .frame(maxWidth: 220)
                    }
                    .padding(.horizontal, 32)
                } else if unlocked.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("No summaries unlocked yet")
                            .foregroundColor(.gray)
                    }
                } else {
                    List(unlocked) { video in
                        NavigationLink(video.title) {
                            SummaryView(video: video)
                        }
                        .foregroundColor(Theme.text(colorScheme))
                        .listRowBackground(Theme.card(colorScheme))
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("My Summaries")
            .sheet(isPresented: $showAuthSheet) {
                AuthSheet()
                    .environmentObject(authService)
            }
        }
    }
}
