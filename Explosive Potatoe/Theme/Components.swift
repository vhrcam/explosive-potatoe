import SwiftUI

struct ChunkyButtonStyle: ButtonStyle {
    enum Kind { case primary, secondary, blue, green, gold }

    var kind: Kind = .primary
    var font: Font = .fredoka(20, .bold)
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
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
                    LinearGradient(colors: [.white.opacity(0.55), .white.opacity(0.05)], startPoint: .top, endPoint: .bottom),
                    lineWidth: 1.5
                )
            )
            .background(shape.fill(lip).offset(y: pressed ? 1 : 5))
            .offset(y: pressed ? 4 : 0)
            .scaleEffect(pressed ? 0.985 : 1)
            .shadow(color: glow.opacity(isEnabled ? 0.45 : 0), radius: 18, y: 8)
            .compositingGroup()
            .saturation(isEnabled ? 1 : 0)
            .opacity(isEnabled ? 1 : 0.4)
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
        case .primary: Color(hex: 0x9E2A14)
        case .secondary: Color.black.opacity(0.35)
        case .blue: Color(hex: 0x1D4FA8)
        case .green: Color(hex: 0x0E7A52)
        case .gold: Color(hex: 0xB86E00)
        }
    }

    private var glow: Color {
        switch kind {
        case .primary: Theme.fire
        case .secondary: .clear
        case .blue: Theme.blue
        case .green: Theme.green
        case .gold: Theme.yellow
        }
    }

    private var textColor: Color {
        kind == .gold ? Color(hex: 0x4A2800) : .white
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
                .foregroundStyle(Theme.text)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Theme.surfaceStrong))
                .overlay(Circle().strokeBorder(Theme.stroke, lineWidth: 1))
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

    var colors: [Color] {
        switch self {
        case .night: [Theme.bgTop, Theme.bgBottom]
        case .slowMo: [Color(hex: 0x0F2C55), Color(hex: 0x060F24)]
        case .danger: [Color(hex: 0x45101E), Color(hex: 0x14040B)]
        case .victory: [Color(hex: 0x2E1858), Color(hex: 0x0D0820)]
        }
    }

    var glow: Color {
        switch self {
        case .night: Theme.fire
        case .slowMo: Theme.blue
        case .danger: Theme.fire
        case .victory: Theme.yellow
        }
    }

    var ember: Color {
        switch self {
        case .slowMo: Color(hex: 0xA8D8FF)
        case .victory: Theme.yellow
        default: Theme.orange
        }
    }
}

struct ScreenBackground: View {
    var mood = Backdrop.night
    @State private var drift = false

    var body: some View {
        ZStack {
            LinearGradient(colors: mood.colors, startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [mood.glow.opacity(0.32), .clear], center: .center, startRadius: 0, endRadius: 260)
                .frame(width: 520, height: 520)
                .offset(x: drift ? 70 : -60, y: drift ? 160 : 240)
            RadialGradient(colors: [Theme.purple.opacity(0.28), .clear], center: .center, startRadius: 0, endRadius: 220)
                .frame(width: 440, height: 440)
                .offset(x: drift ? -110 : 90, y: drift ? -300 : -220)
            EmberField(color: mood.ember)
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.5), value: mood)
        .onAppear {
            withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) { drift = true }
        }
    }
}

struct EmberField: View {
    var count = 26
    var color: Color = Theme.orange

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                for i in 0..<count {
                    let seed = Double(i) + 1
                    let speed = 0.025 + random(seed * 1.7) * 0.05
                    let progress = (t * speed + random(seed * 3.1)).truncatingRemainder(dividingBy: 1)
                    let x = (random(seed * 5.3) + sin(t * 0.7 + seed * 2) * 0.03) * size.width
                    let y = (1.05 - progress * 1.1) * size.height
                    let radius = 1.2 + random(seed * 7.7) * 2.4
                    let alpha = sin(progress * .pi) * (0.35 + random(seed * 9.1) * 0.5)
                    let glow = CGRect(x: x - radius * 3, y: y - radius * 3, width: radius * 6, height: radius * 6)
                    let core = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                    context.fill(Path(ellipseIn: glow), with: .color(color.opacity(alpha * 0.18)))
                    context.fill(Path(ellipseIn: core), with: .color(color.opacity(alpha)))
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func random(_ seed: Double) -> Double {
        let value = sin(seed * 12.9898) * 43758.5453
        return value - value.rounded(.down)
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
            .background(shape.fill(Theme.surface))
            .background(shape.fill(LinearGradient(colors: [.white.opacity(0.06), .clear], startPoint: .top, endPoint: .center)))
            .overlay(shape.strokeBorder(Theme.stroke, lineWidth: 1))
    }

    func bigName(_ color: Color, size: CGFloat = 84) -> some View {
        self
            .font(.lilita(size))
            .foregroundStyle(color)
            .shadow(color: color.opacity(0.55), radius: 20)
            .shadow(color: .black.opacity(0.35), radius: 0, x: 0, y: 4)
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
            .overlay(Circle().strokeBorder(.white.opacity(0.3), lineWidth: 1.5))
            .shadow(color: color.opacity(0.5), radius: 8)
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
            .foregroundStyle(Color(hex: 0x4A2800))
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Capsule().fill(Theme.goldGradient))
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
        .background(Capsule().fill(.black.opacity(0.35)))
        .overlay(Capsule().strokeBorder(Theme.yellow.opacity(0.35), lineWidth: 1))
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
                    Capsule().fill(Theme.surfaceStrong)
                    Capsule()
                        .fill(LinearGradient(colors: [fill.opacity(0.75), fill], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(value) / CGFloat(max(total, 1)))
                        .shadow(color: fill.opacity(0.6), radius: 8)
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
        .background(Capsule().fill(.black.opacity(0.35)))
        .overlay(Capsule().strokeBorder(Theme.yellow.opacity(0.3), lineWidth: 1))
    }
}

struct MinigameHeader: View {
    var label: String?
    var labelColor: Color = Theme.textDim
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(spacing: 10) {
            if let label {
                SectionLabel(text: label, color: labelColor)
            }
            Text(title)
                .font(.lilita(40))
                .foregroundStyle(Theme.text)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
            if let subtitle {
                Text(subtitle)
                    .font(.fredoka(16))
                    .foregroundStyle(Theme.textDim)
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
                .foregroundStyle(Theme.textDim)
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

struct GlowPotato: View {
    let mood: PotatoImage.Mood
    let width: CGFloat
    var glow: Color = Theme.orange
    var bobs = true
    @State private var bob = false

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [glow.opacity(0.55), glow.opacity(0.15), .clear], center: .center, startRadius: 0, endRadius: width * 0.75))
                .frame(width: width * 1.6, height: width * 1.6)
                .scaleEffect(bob ? 1.06 : 0.96)
            Ellipse()
                .fill(.black.opacity(0.35))
                .frame(width: width * 0.6, height: width * 0.09)
                .blur(radius: 6)
                .offset(y: width * 0.62)
                .scaleEffect(bob ? 0.88 : 1)
            PotatoImage(mood: mood, width: width)
                .offset(y: bob ? -width * 0.04 : 0)
        }
        .onAppear {
            guard bobs else { return }
            withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) { bob = true }
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
