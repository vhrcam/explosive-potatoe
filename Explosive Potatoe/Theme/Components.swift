import SwiftUI

struct ChunkyButtonStyle: ButtonStyle {
    enum Kind { case primary, secondary, blue, green, gold }

    var kind: Kind = .primary
    var font: Font = .fredoka(20, .bold)
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        configuration.label
            .font(font)
            .foregroundStyle(textColor)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .padding(.horizontal, 20)
            .background(shape.fill(fill))
            .overlay(
                shape.strokeBorder(
                    LinearGradient(colors: [.white.opacity(0.5), .white.opacity(0)], startPoint: .top, endPoint: .center),
                    lineWidth: 1.5
                )
            )
            .overlay(shape.strokeBorder(Theme.ink.opacity(kind == .secondary ? 0.22 : 0.35), lineWidth: 1.5))
            .background(shape.fill(lip).offset(y: pressed ? 1 : 5))
            .offset(y: pressed ? 4 : 0)
            .scaleEffect(pressed ? 0.985 : 1)
            .shadow(color: Theme.shadow.opacity(isEnabled ? 1 : 0), radius: pressed ? 2 : 7, y: pressed ? 2 : 6)
            .compositingGroup()
            .saturation(isEnabled ? 1 : 0)
            .opacity(isEnabled ? 1 : 0.45)
            .animation(.spring(response: 0.22, dampingFraction: 0.6), value: pressed)
            .onChange(of: pressed) {
                if pressed {
                    Haptics.tap()
                    SFX.play(.tap)
                }
            }
    }

    private var fill: AnyShapeStyle {
        switch kind {
        case .primary: AnyShapeStyle(Theme.fireGradient)
        case .secondary: AnyShapeStyle(Theme.glassGradient)
        case .blue: AnyShapeStyle(Theme.blueGradient)
        case .green: AnyShapeStyle(Theme.greenGradient)
        case .gold: AnyShapeStyle(Theme.goldGradient)
        }
    }

    private var lip: Color {
        switch kind {
        case .primary: Color(hex: 0x8E2414)
        case .secondary: Color(hex: 0xC9B48E)
        case .blue: Color(hex: 0x1A4B85)
        case .green: Color(hex: 0x17603A)
        case .gold: Color(hex: 0xA8680A)
        }
    }

    private var textColor: Color {
        switch kind {
        case .secondary: Theme.ink
        case .gold: Color(hex: 0x3E2400)
        default: .white
        }
    }
}

extension ButtonStyle where Self == ChunkyButtonStyle {
    static func chunky(_ kind: ChunkyButtonStyle.Kind = .primary) -> ChunkyButtonStyle {
        ChunkyButtonStyle(kind: kind)
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
}

struct CircleIconButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            SFX.play(.tap)
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(Theme.ink)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Theme.card))
                .overlay(Circle().strokeBorder(Theme.stroke, lineWidth: 1))
                .shadow(color: Theme.shadow, radius: 4, y: 3)
        }
        .buttonStyle(.pressable)
    }
}

struct Pill: View {
    let text: String
    var fill: Color = Theme.surfaceStrong
    var textColor: Color = Theme.text
    var border: Color = Theme.stroke
    var dashed = false
    var size: CGFloat = 15

    var body: some View {
        Text(text)
            .font(.fredoka(size, .bold))
            .foregroundStyle(textColor)
            .lineLimit(1)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(Capsule().fill(fill))
            .overlay(
                Capsule().strokeBorder(border, style: StrokeStyle(lineWidth: 1.2, dash: dashed ? [5, 4] : []))
            )
    }
}

struct SectionLabel: View {
    let text: String
    var color: Color = Theme.textDim
    var alignment: Alignment = .center

    var body: some View {
        Text(text.uppercased())
            .font(.fredoka(13, .bold))
            .tracking(1.6)
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, alignment: alignment)
    }
}

enum Backdrop {
    case night, slowMo, danger, victory

    var wash: Color {
        switch self {
        case .night: .clear
        case .slowMo: Color(hex: 0x6FA8E8).opacity(0.22)
        case .danger: Color(hex: 0xE2442B).opacity(0.16)
        case .victory: Color(hex: 0xF2B530).opacity(0.2)
        }
    }

    var edge: Color {
        switch self {
        case .night: Color(hex: 0x7A5B36).opacity(0.18)
        case .slowMo: Color(hex: 0x1D4F8A).opacity(0.3)
        case .danger: Color(hex: 0x3A1206).opacity(0.55)
        case .victory: Color(hex: 0xA8680A).opacity(0.28)
        }
    }
}

struct ScreenBackground: View {
    var mood = Backdrop.night

    var body: some View {
        ZStack {
            Theme.paper
            Image("PaperTexture")
                .resizable()
                .scaledToFill()
            mood.wash
            RadialGradient(colors: [.clear, .clear, mood.edge], center: .center, startRadius: 120, endRadius: 560)
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.4), value: mood)
        .allowsHitTesting(false)
    }
}

private struct NoteCardBackground: View {
    var lineSpacing: CGFloat = 30
    var topInset: CGFloat = 46

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Theme.card)
            Canvas { context, size in
                var y = topInset
                while y < size.height - 8 {
                    var line = Path()
                    line.move(to: CGPoint(x: 0, y: y))
                    line.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(line, with: .color(Theme.noteRule), lineWidth: 1)
                    y += lineSpacing
                }
                var margin = Path()
                margin.move(to: CGPoint(x: 34, y: 0))
                margin.addLine(to: CGPoint(x: 34, y: size.height))
                context.stroke(margin, with: .color(Theme.noteMargin), lineWidth: 1.2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .shadow(color: Theme.shadow, radius: 10, y: 6)
    }
}

private struct TapeStrip: View {
    var body: some View {
        Rectangle()
            .fill(Color(hex: 0xF3E3A6).opacity(0.75))
            .overlay(Rectangle().strokeBorder(Theme.ink.opacity(0.06), lineWidth: 1))
            .frame(width: 86, height: 24)
            .rotationEffect(.degrees(-3))
            .shadow(color: Theme.shadow.opacity(0.5), radius: 1, y: 1)
    }
}

extension View {
    func screen(_ mood: Backdrop = .night) -> some View {
        self
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(ScreenBackground(mood: mood))
    }

    func glassCard(cornerRadius: CGFloat = 24, padding: CGFloat = 20) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return self
            .padding(padding)
            .background(shape.fill(Theme.surfaceStrong))
            .overlay(shape.strokeBorder(Theme.stroke, lineWidth: 1))
            .shadow(color: Theme.shadow, radius: 8, y: 4)
    }

    func noteCard(rotation: Double = 0, padding: CGFloat = 20, taped: Bool = true) -> some View {
        self
            .padding(.leading, 26)
            .padding(padding)
            .padding(.top, 12)
            .background(NoteCardBackground())
            .overlay(alignment: .top) {
                if taped { TapeStrip().offset(y: -10) }
            }
            .rotationEffect(.degrees(rotation))
    }

    func bigName(_ color: Color, size: CGFloat = 84) -> some View {
        self
            .font(.lilita(size))
            .foregroundStyle(color)
            .shadow(color: Theme.ink.opacity(0.28), radius: 0, x: 2, y: 3)
            .lineLimit(1)
            .minimumScaleFactor(0.4)
    }
}

struct Avatar: View {
    let name: String
    let colorIndex: Int
    var size: CGFloat = 38

    var body: some View {
        let color = Theme.avatarColors[colorIndex % Theme.avatarColors.count]
        Text(String(name.prefix(1)).uppercased())
            .font(.lilita(size * 0.5))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Circle().fill(LinearGradient(colors: [color.opacity(0.85), color], startPoint: .top, endPoint: .bottom)))
            .overlay(Circle().strokeBorder(.white.opacity(0.7), lineWidth: 2))
            .shadow(color: Theme.shadow, radius: 3, y: 2)
    }
}

struct GameHUD: View {
    let game: GameModel

    var body: some View {
        HStack {
            Pill(text: "ROUND \(game.round)/\(game.gameType.rounds)", size: 13)
            Spacer()
            FuseTimePill(game: game)
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 11, weight: .bold))
                Text("\(game.players[game.holder].points)")
                    .contentTransition(.numericText(value: Double(game.players[game.holder].points)))
            }
            .font(.fredoka(14, .bold))
            .foregroundStyle(Color(hex: 0x3E2400))
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Capsule().fill(Theme.goldGradient))
            .overlay(Capsule().strokeBorder(Theme.ink.opacity(0.25), lineWidth: 1))
            .animation(.spring, value: game.players[game.holder].points)
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
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(Capsule().fill(Theme.ink))
    }
}

struct ProgressBarView: View {
    let value: Int
    let total: Int
    var fill: Color = Theme.green
    var labelColor: Color = Theme.text

    var body: some View {
        HStack(spacing: 12) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.ink.opacity(0.08))
                    Capsule()
                        .fill(LinearGradient(colors: [fill.opacity(0.8), fill], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(value) / CGFloat(max(total, 1)))
                    Capsule().strokeBorder(Theme.ink.opacity(0.15), lineWidth: 1)
                }
            }
            .frame(height: 12)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: value)

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
                .font(.fredoka(15, .semibold))
                .foregroundStyle(Theme.yellow)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(Capsule().fill(Theme.ink))
    }
}

struct CompleteFooter: View {
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Back to the potato. It's still burning!")
                .font(.fredoka(16))
                .foregroundStyle(Theme.textDim)
            Spacer(minLength: 0)
            Button("Back to the Potato", action: onDone)
                .buttonStyle(.chunky(.green))
        }
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
