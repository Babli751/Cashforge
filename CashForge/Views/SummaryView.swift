import SwiftUI

struct SummaryView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    let video: VideoItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(video.title)
                    .font(.title2.bold())
                    .foregroundColor(Theme.text(colorScheme))

                Text("Summary")
                    .font(.subheadline.bold())
                    .foregroundColor(Theme.gold(colorScheme))

                Text(video.summaryMarkdown)
                    .font(.body)
                    .foregroundColor(Theme.text(colorScheme))
                    .lineSpacing(4)

                if !video.keyPoints.isEmpty {
                    Text("Key Points")
                        .font(.subheadline.bold())
                        .foregroundColor(Theme.gold(colorScheme))
                        .padding(.top, 8)

                    ForEach(video.keyPoints, id: \.self) { point in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundColor(Theme.success)
                                .padding(.top, 6)
                            Text(point)
                                .foregroundColor(Theme.text(colorScheme))
                        }
                    }
                }
            }
            .padding()
        }
        .background(Theme.background(colorScheme).ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            Button("Start Business Simulation →") {
                store.applyLesson(video.title)
                store.selectedTab = 2
                dismiss()
            }
            .buttonStyle(GreenButtonStyle())
            .padding()
            .background(Theme.background(colorScheme))
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
