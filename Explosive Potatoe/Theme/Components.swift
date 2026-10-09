import SwiftUI

struct ChunkyButtonStyle: ButtonStyle {
    enum Kind { case primary, secondary, blue, green }

    var kind: Kind = .primary
    var font: Font = .fredoka(21, .bold)
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .font(font)
            .foregroundStyle(kind == .secondary ? Theme.ink : .white)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .padding(.horizontal, 20)
            .background(RoundedRectangle(cornerRadius: 22).fill(colors.fill))
            .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Theme.ink, lineWidth: 3))
            .background(RoundedRectangle(cornerRadius: 22).fill(colors.shadow).offset(y: pressed ? 2 : 6))
            .offset(y: pressed ? 4 : 0)
            .compositingGroup()
            .saturation(isEnabled ? 1 : 0.4)
            .opacity(isEnabled ? 1 : 0.5)
    }

    private var colors: (fill: Color, shadow: Color) {
        switch kind {
        case .primary: (Theme.red, Theme.redShadow)
        case .secondary: (Theme.creamDeep, Theme.potatoDark)
        case .blue: (Theme.blue, Theme.blueShadow)
        case .green: (Theme.green, Theme.greenShadow)
        }
    }
}

extension ButtonStyle where Self == ChunkyButtonStyle {
    static func chunky(_ kind: ChunkyButtonStyle.Kind = .primary) -> ChunkyButtonStyle {
        ChunkyButtonStyle(kind: kind)
    }
}

struct Pill: View {
    let text: String
    var fill: Color = .white
    var textColor: Color = Theme.ink
    var border: Color = Theme.ink
    var dashed = false
    var size: CGFloat = 15

    var body: some View {
        Text(text)
            .font(.fredoka(size, .bold))
            .foregroundStyle(textColor)
            .lineLimit(1)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Capsule().fill(fill))
            .overlay(
                Capsule().strokeBorder(border, style: StrokeStyle(lineWidth: 2.5, dash: dashed ? [6, 4] : []))
            )
    }
}

struct SectionLabel: View {
    let text: String
    var color: Color = Theme.inkMuted
    var alignment: Alignment = .center

    var body: some View {
        Text(text.uppercased())
            .font(.fredoka(13, .bold))
            .tracking(1.4)
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, alignment: alignment)
    }
}

struct ScreenBackground: View {
    var color = Theme.cream
    var blob = Theme.creamDeep

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                color
                Circle()
                    .fill(blob)
                    .frame(width: 220, height: 220)
                    .offset(x: geo.size.width - 123, y: 70)
                Circle()
                    .fill(blob)
                    .frame(width: 320, height: 320)
                    .offset(x: -150, y: geo.size.height - 252)
            }
        }
        .ignoresSafeArea()
    }
}

extension View {
    func screen(_ color: Color = Theme.cream, blob: Color = Theme.creamDeep) -> some View {
        self
            .padding(.horizontal, 32)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(ScreenBackground(color: color, blob: blob))
    }

    func bigName(_ color: Color, size: CGFloat = 84) -> some View {
        self
            .font(.lilita(size))
            .foregroundStyle(color)
            .shadow(color: Theme.ink, radius: 0, x: 0, y: 5)
            .lineLimit(1)
            .minimumScaleFactor(0.4)
    }
}

struct Avatar: View {
    let name: String
    let colorIndex: Int
    var size: CGFloat = 38

    var body: some View {
        Text(String(name.prefix(1)).uppercased())
            .font(.fredoka(size * 0.5, .bold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Circle().fill(Theme.avatarColors[colorIndex % Theme.avatarColors.count]))
            .overlay(Circle().strokeBorder(Theme.ink, lineWidth: 2))
    }
}

struct GameHUD: View {
    let game: GameModel

    var body: some View {
        HStack {
            Pill(text: "ROUND \(game.round)/\(game.gameType.rounds)", size: 14)
            Spacer()
            FuseTimePill(game: game)
            Spacer()
            Pill(text: "\(game.players[game.holder].points) pts", fill: Theme.yellow, size: 14)
        }
    }
}

private struct FuseTimePill: View {
    let game: GameModel

    var body: some View {
        HStack(spacing: 6) {
            FuseIcon()
            Text(game.fuseText)
                .font(.fredoka(14, .bold))
                .foregroundStyle(Theme.yellow)
                .monospacedDigit()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(Capsule().fill(Theme.ink))
    }
}

struct ProgressBarView: View {
    let value: Int
    let total: Int
    var fill: Color = Theme.green
    var labelColor: Color = Theme.ink

    var body: some View {
        HStack(spacing: 12) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.creamDeep)
                    Capsule()
                        .fill(fill)
                        .frame(width: geo.size.width * CGFloat(value) / CGFloat(max(total, 1)))
                    Capsule().strokeBorder(Theme.ink, lineWidth: 2.5)
                }
            }
            .frame(height: 16)
            .animation(.easeOut(duration: 0.2), value: value)

            Text("\(value) / \(total)")
                .font(.fredoka(15, .bold))
                .foregroundStyle(labelColor)
                .monospacedDigit()
        }
    }
}

struct FuseWarning: View {
    var body: some View {
        HStack(spacing: 10) {
            FuseIcon()
            Text("The fuse never stops. Hurry!")
                .font(.fredoka(16, .semibold))
                .foregroundStyle(Theme.yellow)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Capsule().fill(Theme.ink))
    }
}

struct MinigameHeader: View {
    var label: String?
    var labelColor: Color = Theme.inkMuted
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(spacing: 14) {
            if let label {
                SectionLabel(text: label, color: labelColor)
            }
            Text(title)
                .font(.lilita(42))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
            if let subtitle {
                Text(subtitle)
                    .font(.fredoka(16))
                    .foregroundStyle(Theme.inkMuted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct CompleteFooter: View {
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Back to the potato. It's still burning!")
                .font(.fredoka(16))
                .foregroundStyle(Theme.inkMuted)
            Spacer(minLength: 0)
            Button("Back to the Potato", action: onDone)
                .buttonStyle(.chunky(.green))
        }
    }
}

struct PotatoImage: View {
    enum Mood: String { case happy = "PotatoHappy", nervous = "PotatoNervous", boom = "PotatoBoom" }

    let mood: Mood
    var width: CGFloat

    var body: some View {
        Image(mood.rawValue)
            .resizable()
            .scaledToFit()
            .frame(width: width)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var widest: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            widest = max(widest, x - spacing)
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: widest, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
