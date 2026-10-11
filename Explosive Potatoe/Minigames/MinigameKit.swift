import SwiftUI

enum MinigameFX {
    static let winPoints = 15
    static let completeLabel = "Minigame complete · +\(winPoints)"

    static func step(_ progress: Double = 0) {
        SFX.play(.pop, pitch: Float(0.9 + progress * 0.7))
        Haptics.tap()
    }

    static func win() {
        SFX.play(.success)
        Haptics.success()
    }

    static func miss() {
        SFX.play(.fail)
        Haptics.fail()
    }
}

struct Shake: GeometryEffect {
    var amount: CGFloat = 12
    var shakes: CGFloat = 4
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: amount * sin(animatableData * .pi * shakes), y: 0))
    }
}

extension View {
    func shake(_ count: Int, amount: CGFloat = 12) -> some View {
        modifier(Shake(amount: amount, animatableData: CGFloat(count)))
            .animation(.linear(duration: 0.4), value: count)
    }
}

struct Burst: View {
    var colors = [Theme.yellow, Theme.orange, Theme.fire, Theme.green, Theme.blue, Theme.pink]
    var count = 22
    var distance: CGFloat = 150
    var pieceSize: CGFloat = 14

    @State private var flown = false
    @State private var faded = false

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                let angle = Double(i) / Double(count) * 2 * .pi + unit(i * 3) * 0.4
                let reach = distance * (0.55 + 0.45 * unit(i * 7))
                let color = colors[i % colors.count]
                Group {
                    if i.isMultiple(of: 3) {
                        SparkleShape()
                            .fill(color)
                            .frame(width: pieceSize * 1.2, height: pieceSize * 1.2)
                    } else {
                        Capsule()
                            .fill(color)
                            .frame(width: pieceSize * 0.4, height: pieceSize)
                            .rotationEffect(.radians(angle + .pi / 2))
                    }
                }
                .shadow(color: color.opacity(0.8), radius: 6)
                .offset(x: flown ? cos(angle) * reach : 0, y: flown ? sin(angle) * reach : 0)
                .scaleEffect(faded ? 0.3 : 1)
                .opacity(faded ? 0 : 1)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) { flown = true }
            withAnimation(.easeIn(duration: 0.45).delay(0.35)) { faded = true }
        }
    }

    private func unit(_ n: Int) -> Double {
        let value = sin(Double(n + 1) * 12.9898) * 43758.5453
        return value - value.rounded(.down)
    }
}

struct WinPop: View {
    var size: CGFloat = 120

    @State private var shown = false

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Theme.green.opacity(0.55), .clear], center: .center, startRadius: 0, endRadius: size))
                .frame(width: size * 2, height: size * 2)
                .scaleEffect(shown ? 1 : 0.3)
            Burst(distance: size * 1.35)
            ResultBadge(isCheck: true, size: size)
                .shadow(color: Theme.green.opacity(0.7), radius: 20)
                .scaleEffect(shown ? 1 : 0.2)
                .rotationEffect(.degrees(shown ? 0 : -40))
            Text("+\(MinigameFX.winPoints)")
                .font(.lilita(36))
                .foregroundStyle(Theme.goldGradient)
                .shadow(color: Theme.orange.opacity(0.9), radius: 12)
                .offset(y: shown ? -size * 0.95 : -size * 0.35)
                .opacity(shown ? 1 : 0)
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) { shown = true }
        }
    }
}

struct MissPop: View {
    var size: CGFloat = 100

    @State private var shown = false

    var body: some View {
        ResultBadge(isCheck: false, size: size)
            .shadow(color: Theme.fire.opacity(0.8), radius: 20)
            .scaleEffect(shown ? 1 : 0.3)
            .rotationEffect(.degrees(shown ? 0 : 30))
            .allowsHitTesting(false)
            .onAppear {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { shown = true }
            }
    }
}

struct StreakPips: View {
    let value: Int
    let total: Int
    var color: Color = Theme.green

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<total, id: \.self) { i in
                let lit = i < value
                Circle()
                    .fill(lit ? AnyShapeStyle(LinearGradient(colors: [.white.opacity(0.9), color], startPoint: .top, endPoint: .center)) : AnyShapeStyle(Theme.surfaceStrong))
                    .overlay(Circle().strokeBorder(lit ? color : Theme.stroke, lineWidth: 1.5))
                    .frame(width: 18, height: 18)
                    .shadow(color: color.opacity(lit ? 0.8 : 0), radius: 8)
                    .scaleEffect(lit ? 1.15 : 1)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: value)
    }
}
