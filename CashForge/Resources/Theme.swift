import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        }
    }

    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

enum Theme {
    static let success = Color(hex: 0x10B981)
    static let danger = Color(hex: 0xEF4444)

    static let cardRadius: CGFloat = 14

    /// Gold shifts darker/more saturated in Light Mode for contrast against white — the Dark Mode
    /// gold (D4AF37) reads as washed-out and low-contrast on a light background.
    static func gold(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: 0xD4AF37) : Color(hex: 0x9C6B0B)
    }

    /// Adaptive colors: custom dark palette in Dark Mode, iOS system colors in Light Mode.
    static func background(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: 0x0F0F0F) : Color(.systemBackground)
    }

    static func card(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: 0x1A1A1A) : Color(hex: 0xF5EFE0)
    }

    static func text(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: 0xF5F5F5) : Color(.label)
    }
}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

struct GoldButtonStyle: ButtonStyle {
    var outline: Bool = false
    @Environment(\.colorScheme) var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        let gold = Theme.gold(colorScheme)
        configuration.label
            .font(.headline)
            .foregroundColor(outline ? gold : (colorScheme == .dark ? .black : .white))
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(outline ? Color.clear : gold)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(gold, lineWidth: outline ? 1.5 : 0)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct GreenButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.bold())
            .foregroundColor(.white)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(Theme.success)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
