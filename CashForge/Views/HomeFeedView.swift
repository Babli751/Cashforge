import SwiftUI

struct HomeFeedView: View {
    @EnvironmentObject var store: AppStore
    @State private var search: String = ""
    @Environment(\.colorScheme) var colorScheme

    var filtered: [VideoItem] {
        search.isEmpty ? store.videos : store.videos.filter { $0.title.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background(colorScheme).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        SearchBar(text: $search)
                            .padding(.horizontal)

                        if store.isLoading {
                            ProgressView().tint(Theme.gold(colorScheme)).padding(.top, 40)
                        } else if let error = store.errorMessage, store.videos.isEmpty {
                            EmptyStateView(
                                icon: "wifi.slash",
                                title: "Couldn't load videos",
                                subtitle: error
                            )
                        } else if filtered.isEmpty && !search.isEmpty {
                            EmptyStateView(
                                icon: "magnifyingglass",
                                title: "No results",
                                subtitle: "No videos match \"\(search)\""
                            )
                        } else if filtered.isEmpty {
                            EmptyStateView(
                                icon: "film",
                                title: "No videos yet",
                                subtitle: "Check back soon for new content"
                            )
                        }

                        ForEach(filtered) { video in
                            NavigationLink(value: video) {
                                VideoCard(video: video)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical)
                }
                .refreshable { await store.loadVideos() }
            }
            .navigationTitle("CashForge")
            .navigationDestination(for: VideoItem.self) { video in
                VideoDetailView(video: video)
            }
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundColor(.gray)
            Text(title)
                .font(.headline)
                .foregroundColor(Theme.text(colorScheme))
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
        .padding(.horizontal, 32)
    }
}

struct SearchBar: View {
    @Binding var text: String
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(.gray)
            TextField("Search videos", text: $text)
                .foregroundColor(Theme.text(colorScheme))
        }
        .padding(10)
        .background(Theme.card(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct VideoCard: View {
    let video: VideoItem
    @Environment(\.colorScheme) var colorScheme

    private var thumbnailURL: URL? {
        if let custom = video.thumbnailURL, let url = URL(string: custom) {
            return url
        }
        if let ytID = video.youtubeID {
            return URL(string: "https://img.youtube.com/vi/\(ytID)/hqdefault.jpg")
        }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            GeometryReader { geo in
                ZStack {
                    Color.black.opacity(0.4)

                    AsyncImage(url: thumbnailURL) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fill)
                        default:
                            Image(systemName: "play.rectangle.fill")
                                .font(.largeTitle)
                                .foregroundColor(Theme.gold(colorScheme).opacity(0.8))
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                }
            }
            .aspectRatio(16/9, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))

            Text(video.title)
                .font(.headline)
                .foregroundColor(Theme.text(colorScheme))

            Text(video.teaser)
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(2)

            HStack(spacing: 10) {
                Label(video.isUnlocked ? "Open Summary" : "Watch", systemImage: "play.fill")
                    .font(.subheadline.bold())
                    .foregroundColor(Theme.gold(colorScheme))
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.gold(colorScheme), lineWidth: 1.5))

                Label(video.isUnlocked ? "Unlocked" : "Unlock Summary", systemImage: video.isUnlocked ? "checkmark.circle.fill" : "lock.fill")
                    .font(.subheadline.bold())
                    .foregroundColor(.black)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Theme.gold(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(Theme.card(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
        .padding(.horizontal)
    }
}
