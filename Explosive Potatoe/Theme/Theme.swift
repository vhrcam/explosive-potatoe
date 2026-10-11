import SwiftUI
import CoreText

enum Theme {
    static let paper = Color(hex: 0xF4EBD9)
    static let paperDeep = Color(hex: 0xE8DCC3)
    static let kraft = Color(hex: 0xC9A57A)
    static let card = Color(hex: 0xFFFDF7)
    static let bgTop = paper
    static let bgBottom = paperDeep

    static let ink = Color(hex: 0x2A2118)
    static let text = ink
    static let textDim = ink.opacity(0.62)
    static let textFaint = ink.opacity(0.38)

    static let surface = Color.white.opacity(0.55)
    static let surfaceStrong = Color.white.opacity(0.85)
    static let stroke = ink.opacity(0.14)
    static let shadow = Color(hex: 0x5A4630).opacity(0.22)

    static let fire = Color(hex: 0xE2442B)
    static let orange = Color(hex: 0xEE7A26)
    static let yellow = Color(hex: 0xF2B530)
    static let green = Color(hex: 0x2E9E62)
    static let blue = Color(hex: 0x2F7FD1)
    static let pink = Color(hex: 0xE24C7C)
    static let purple = Color(hex: 0x7B55D6)
    static let potato = Color(hex: 0xC99555)

    static let fireGradient = LinearGradient(colors: [Color(hex: 0xEF5A3A), Color(hex: 0xD63A22)], startPoint: .top, endPoint: .bottom)
    static let greenGradient = LinearGradient(colors: [Color(hex: 0x3DB274), Color(hex: 0x248A53)], startPoint: .top, endPoint: .bottom)
    static let blueGradient = LinearGradient(colors: [Color(hex: 0x4592DE), Color(hex: 0x2670C2)], startPoint: .top, endPoint: .bottom)
    static let goldGradient = LinearGradient(colors: [Color(hex: 0xF7C64A), Color(hex: 0xEAA21F)], startPoint: .top, endPoint: .bottom)
    static let glassGradient = LinearGradient(colors: [Color(hex: 0xFFFEFA), Color(hex: 0xF6EEDD)], startPoint: .top, endPoint: .bottom)

    static let noteRule = Color(hex: 0x8DB4E2).opacity(0.55)
    static let noteMargin = Color(hex: 0xE2757A).opacity(0.7)

    static let avatarColors = [orange, blue, green, pink, purple, yellow]
    static let crateColors = [fire, blue, green]
    static let crateDark = [Color(hex: 0x9E2A17), Color(hex: 0x1D5596), Color(hex: 0x1B6E42)]
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
    private static let hasCaveat = UIFont.familyNames.contains("Caveat")

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

    static func hand(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        if hasCaveat {
            return .custom("Caveat", size: size).weight(weight)
        }
        return .system(size: size, weight: weight, design: .serif).italic()
    }
}
