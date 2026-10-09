import SwiftUI
import CoreText

enum Theme {
    static let cream = Color(hex: 0xFFF4E0)
    static let creamDeep = Color(hex: 0xF6E3BF)
    static let ink = Color(hex: 0x3B2A1A)
    static let inkMuted = Color(hex: 0x8A7560)
    static let red = Color(hex: 0xFF5A36)
    static let redShadow = Color(hex: 0xB8381C)
    static let potato = Color(hex: 0xE3A95C)
    static let potatoDark = Color(hex: 0x6B4423)
    static let green = Color(hex: 0x4CB86A)
    static let greenShadow = Color(hex: 0x2F8A4C)
    static let blue = Color(hex: 0x4F9BE0)
    static let blueShadow = Color(hex: 0x2E6DB0)
    static let yellow = Color(hex: 0xFFC93C)
    static let spark = Color(hex: 0xFF7A2F)
    static let slowMo = Color(hex: 0xDCE3E1)
    static let slowMoBlob = Color(hex: 0xCDD6D3)
    static let rowShadow = Color(hex: 0xE2CFAE)
    static let tileShadow = Color(hex: 0xCDB99C)

    static let avatarColors = [potato, blue, green, red]
    static let crateColors = [red, blue, green]
    static let crateDark = [redShadow, blueShadow, greenShadow]
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
    static func fredoka(_ size: CGFloat, _ weight: Font.Weight = .medium) -> Font {
        if UIFont.familyNames.contains("Fredoka") {
            return .custom("Fredoka", size: size).weight(weight)
        }
        return .system(size: size, weight: weight, design: .rounded)
    }

    static func lilita(_ size: CGFloat) -> Font {
        if UIFont.familyNames.contains("Lilita One") {
            return .custom("LilitaOne", size: size)
        }
        return .system(size: size, weight: .black, design: .rounded)
    }
}
