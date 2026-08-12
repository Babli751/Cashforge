import SwiftUI

struct SplashView: View {
    @State private var showRoot = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        if showRoot {
            RootTabView()
        } else {
            ZStack {
                Theme.background(colorScheme).ignoresSafeArea()
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "hammer.fill")
                            .foregroundColor(Theme.gold(colorScheme))
                            .font(.system(size: 28))
                        Text("CashForge")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.text(colorScheme))
                    }
                    Text("Forge real business skills")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation { showRoot = true }
                }
            }
        }
    }
}
