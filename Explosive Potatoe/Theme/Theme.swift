import SwiftUI
import CoreText

enum Theme {
    static let bgTop = Color(hex: 0x22123F)
    static let bgBottom = Color(hex: 0x0D0820)
    static let surface = Color.white.opacity(0.07)
    static let surfaceStrong = Color.white.opacity(0.12)
    static let stroke = Color.white.opacity(0.14)

    static let text = Color(hex: 0xFFF4E6)
    static let textDim = text.opacity(0.62)
    static let textFaint = text.opacity(0.38)

    static let fire = Color(hex: 0xFF5A2E)
    static let orange = Color(hex: 0xFF8A1F)
    static let yellow = Color(hex: 0xFFD23F)
    static let green = Color(hex: 0x34D399)
    static let blue = Color(hex: 0x4FA8FF)
    static let pink = Color(hex: 0xFF4D8D)
    static let purple = Color(hex: 0x8B5CF6)
    static let potato = Color(hex: 0xE3A95C)

    static let fireGradient = LinearGradient(colors: [Color(hex: 0xFF8A3D), Color(hex: 0xFF4B2B)], startPoint: .top, endPoint: .bottom)
    static let greenGradient = LinearGradient(colors: [Color(hex: 0x5BE6AE), Color(hex: 0x1FB67E)], startPoint: .top, endPoint: .bottom)
    static let blueGradient = LinearGradient(colors: [Color(hex: 0x7CC0FF), Color(hex: 0x3A82F6)], startPoint: .top, endPoint: .bottom)
    static let goldGradient = LinearGradient(colors: [Color(hex: 0xFFE27A), Color(hex: 0xFFB21F)], startPoint: .top, endPoint: .bottom)
    static let glassGradient = LinearGradient(colors: [Color.white.opacity(0.16), Color.white.opacity(0.06)], startPoint: .top, endPoint: .bottom)

    static let avatarColors = [orange, blue, green, pink, purple, yellow]
    static let crateColors = [fire, blue, green]
    static let crateDark = [Color(hex: 0xA8321A), Color(hex: 0x2459B8), Color(hex: 0x14845A)]
    static let crateNames = ["Red", "Blue", "Green"]

    static func registerFonts() {
        let urls = ["ttf", "otf"].flatMap { Bundle.main.urls(forResourcesWithExtension: $0, subdirectory: nil) ?? [] }
        CTFontManagerRegisterFontURLs(urls as CFArray, .process, true, nil)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

extension Font {
    private static let hasFredoka = UIFont.familyNames.contains("Fredoka")
    private static let hasLilita = UIFont.familyNames.contains("Lilita One")

    static func fredoka(_ size: CGFloat, _ weight: Font.Weight = .medium) -> Font {
        if hasFredoka {
            return .custom("Fredoka", size: size).weight(weight)
        }
        return .system(size: size, weight: weight, design: .rounded)
    }

    static func lilita(_ size: CGFloat) -> Font {
        if hasLilita {
            return .custom("Lilita One", size: size)
        }
        return .system(size: size, weight: .black, design: .rounded)
    }
}
