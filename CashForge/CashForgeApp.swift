import SwiftUI

@main
struct CashForgeApp: App {
    @AppStorage("appTheme") private var appThemeRaw: String = AppTheme.dark.rawValue

    var body: some Scene {
        WindowGroup {
            SplashView()
                .preferredColorScheme((AppTheme(rawValue: appThemeRaw) ?? .dark).colorScheme)
        }
    }
}
