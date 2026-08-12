import SwiftUI
import WebKit

struct VideoDetailView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var authService: AuthService
    let video: VideoItem
    @State private var unlocking = false
    @State private var showSummary = false
    @State private var showAuthSheet = false
    @Environment(\.colorScheme) var colorScheme

    private var current: VideoItem {
        store.videos.first(where: { $0.id == video.id }) ?? video
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VideoPlayerWebView(url: video.embedURL)
                    .aspectRatio(16/9, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
                    .padding(.horizontal)

                Text(video.title)
                    .font(.title2.bold())
                    .foregroundColor(Theme.text(colorScheme))
                    .padding(.horizontal)

                Text(video.teaser)
                    .font(.body)
                    .foregroundColor(.gray)
                    .padding(.horizontal)

                Divider().background(Color.gray.opacity(0.3)).padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {
                    Label("Full Summary + Key Takeaways", systemImage: current.isUnlocked ? "lock.open.fill" : "lock.fill")
                        .font(.headline)
                        .foregroundColor(Theme.gold(colorScheme))

                    if current.isUnlocked {
                        Button("Open Summary") { showSummary = true }
                            .buttonStyle(GoldButtonStyle())
                    } else {
                        Text(video.summaryMarkdown.prefix(80) + "...")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .blur(radius: 4)

                        if authService.isSignedIn {
                            Button {
                                Task {
                                    unlocking = true
                                    _ = await store.unlock(video)
                                    unlocking = false
                                }
                            } label: {
                                if unlocking {
                                    ProgressView().tint(.black)
                                } else {
                                    Text("Unlock for $6.99")
                                }
                            }
                            .buttonStyle(GoldButtonStyle())
                            .disabled(unlocking)
                        } else {
                            Button("Sign In to Unlock") {
                                showAuthSheet = true
                            }
                            .buttonStyle(GoldButtonStyle())
                        }
                    }
                }
                .padding()
                .background(Theme.card(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Theme.background(colorScheme).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showSummary) {
            SummaryView(video: current)
        }
        .sheet(isPresented: $showAuthSheet) {
            AuthSheet()
                .environmentObject(authService)
        }
    }
}

struct VideoPlayerWebView: UIViewRepresentable {
    let url: URL?

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        load(url, into: webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        load(url, into: webView)
    }

    /// Embeds the player inside a minimal local HTML page rather than loading the YouTube URL
    /// directly. Loading the embed URL as the top-level page (no origin) is what triggers
    /// YouTube's Error 153 ("embedding not allowed for this origin") in WKWebView.
    private func load(_ url: URL?, into webView: WKWebView) {
        guard let url else { return }
        let html = """
        <!doctype html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <style>
            html, body { margin: 0; padding: 0; background: transparent; height: 100%; }
            iframe { position: absolute; top: 0; left: 0; width: 100%; height: 100%; border: 0; }
          </style>
        </head>
        <body>
          <iframe src="\(url.absoluteString)"
                  allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                  allowfullscreen></iframe>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.cashforge.app"))
    }
}
