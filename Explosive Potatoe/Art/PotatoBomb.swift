import SwiftUI

private enum Bomb {
    static let heightRatio: CGFloat = 1.3
    static let potatoRatio: CGFloat = 0.8
    static let potatoCenterY: CGFloat = 0.9
    static let stickCenter = CGPoint(x: 0.56, y: 0.45)
    static let stickWidth: CGFloat = 0.16
    static let stickAspect: CGFloat = 560 / 180
    static let stickTilt = 12.0
    static let entry = CGPoint(x: 0.525, y: 0.13)
    static let fuseBase = CGPoint(x: 0.607, y: 0.229)
    static let fuseC1 = CGPoint(x: 0.62, y: 0.13)
    static let fuseC2 = CGPoint(x: 0.79, y: 0.16)
    static let fuseTip = CGPoint(x: 0.75, y: 0.05)
    static let canvasInset = CGSize(width: 0.2, height: 0.3)
    static let cord = Color(hex: 0x4A3A2A)
    static let braid = Color(hex: 0x8F7A5C)
    static let flesh = Color(hex: 0xF1DFA4)
    static let smoke = Color(hex: 0x5E544A)

    static func unit(_ n: Double) -> Double {
        let value = sin(n * 12.9898) * 43758.5453
        return value - value.rounded(.down)
    }

    static func smoothstep(_ a: Double, _ b: Double, _ x: Double) -> Double {
        let t = min(max((x - a) / (b - a), 0), 1)
        return t * t * (3 - 2 * t)
    }
}

struct PotatoBomb: View {
    var width: CGFloat
    var lit: Bool = false
    var shake: Double = 0

    var body: some View {
        TimelineView(.animation(paused: !lit && shake <= 0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            ZStack(alignment: .topLeading) {
                DynamiteStick(width: width)
                    .position(x: Bomb.stickCenter.x * width, y: Bomb.stickCenter.y * width)
                potato
                    .position(x: width / 2, y: Bomb.potatoCenterY * width)
                FuseCord(width: width, lit: lit, time: t)
                    .position(x: width / 2, y: width / 2)
            }
            .frame(width: width, height: width * Bomb.heightRatio, alignment: .topLeading)
            .offset(x: width * shake * (0.022 * sin(t * 61) + 0.01 * sin(t * 97)), y: width * shake * 0.01 * sin(t * 83))
            .rotationEffect(.degrees(shake * 3.5 * sin(t * 47)), anchor: .bottom)
        }
    }

    private var potato: some View {
        Image("PotatoReal")
            .resizable()
            .frame(width: width, height: width * Bomb.potatoRatio)
            .overlay(alignment: .topLeading) {
                Ellipse()
                    .fill(.black.opacity(0.45))
                    .frame(width: width * 0.2, height: width * 0.06)
                    .blur(radius: width * 0.012)
                    .position(x: Bomb.entry.x * width, y: Bomb.entry.y * width)
                    .mask(Image("PotatoReal").resizable())
            }
            .shadow(color: .black.opacity(0.28), radius: width * 0.04, x: 0, y: width * 0.035)
    }
}

private struct DynamiteStick: View {
    let width: CGFloat

    var body: some View {
        Image("Dynamite")
            .resizable()
            .frame(width: width * Bomb.stickWidth, height: width * Bomb.stickWidth * Bomb.stickAspect)
            .shadow(color: .black.opacity(0.2), radius: width * 0.015, x: width * 0.01, y: width * 0.01)
            .rotationEffect(.degrees(Bomb.stickTilt))
    }
}

private struct FuseCord: View {
    let width: CGFloat
    let lit: Bool
    let time: Double

    private let sparkCount = 9
    private let puffCount = 5

    var body: some View {
        Canvas { context, _ in
            let tip = point(Bomb.fuseTip)
            var cord = Path()
            cord.move(to: point(Bomb.fuseBase))
            cord.addCurve(to: tip, control1: point(Bomb.fuseC1), control2: point(Bomb.fuseC2))
            context.stroke(cord, with: .color(Bomb.cord), style: StrokeStyle(lineWidth: width * 0.024, lineCap: .round))
            context.stroke(cord, with: .color(Bomb.braid), style: StrokeStyle(lineWidth: width * 0.012, dash: [width * 0.014, width * 0.016]))
            if lit { drawSpark(&context, at: tip) }
        }
        .frame(width: width * (1 + Bomb.canvasInset.width * 2), height: width * (1 + Bomb.canvasInset.height * 2))
        .allowsHitTesting(false)
    }

    private func point(_ unit: CGPoint) -> CGPoint {
        CGPoint(x: (unit.x + Bomb.canvasInset.width) * width, y: (unit.y + Bomb.canvasInset.height) * width)
    }

    private func drawSpark(_ context: inout GraphicsContext, at tip: CGPoint) {
        for i in 0..<puffCount {
            let p = (time * 0.45 + Double(i) / Double(puffCount)).truncatingRemainder(dividingBy: 1)
            let x = tip.x + width * (0.03 * sin(time * 1.3 + Double(i) * 2) + 0.05 * p)
            let y = tip.y - width * 0.28 * p
            let r = width * (0.015 + 0.05 * p)
            let alpha = 0.3 * (1 - p) * min(p * 5, 1)
            context.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(Bomb.smoke.opacity(alpha)))
        }

        let flicker = 0.85 + 0.15 * sin(time * 40)
        let glow = width * 0.075 * flicker
        context.fill(
            Path(ellipseIn: CGRect(x: tip.x - glow, y: tip.y - glow, width: glow * 2, height: glow * 2)),
            with: .radialGradient(Gradient(colors: [Theme.yellow.opacity(0.95), Theme.orange.opacity(0.45), .clear]), center: tip, startRadius: 0, endRadius: glow)
        )

        let frame = Double(Int(time * 30))
        for i in 0..<sparkCount {
            let seed = frame * 13 + Double(i) * 3.7
            let angle = Bomb.unit(seed) * 2 * .pi
            let length = width * (0.03 + 0.055 * Bomb.unit(seed + 1.3))
            var line = Path()
            line.move(to: CGPoint(x: tip.x + cos(angle) * width * 0.012, y: tip.y + sin(angle) * width * 0.012))
            line.addLine(to: CGPoint(x: tip.x + cos(angle) * length, y: tip.y + sin(angle) * length))
            context.stroke(line, with: .color(i.isMultiple(of: 3) ? .white : Theme.yellow), style: StrokeStyle(lineWidth: width * 0.007, lineCap: .round))
        }

        let core = width * 0.013
        context.fill(Path(ellipseIn: CGRect(x: tip.x - core, y: tip.y - core, width: core * 2, height: core * 2)), with: .color(.white))
    }
}

struct PotatoShatter: View {
    var width: CGFloat
    var onFinished: () -> Void = {}

    @State private var start = Date.now
    @State private var shards = Shard.make()
    @State private var bits = Bit.make()

    private let duration = 1.3
    private let gravity = 4.5
    private let puffCount = 8

    var body: some View {
        TimelineView(.animation) { context in
            let t = min(context.date.timeIntervalSince(start), duration)
            ZStack(alignment: .topLeading) {
                smoke(t)
                flash(t)
                ForEach(shards) { shard in
                    shardView(shard, t)
                }
                stick(t)
                ForEach(bits) { bit in
                    bitView(bit, t)
                }
            }
            .frame(width: width, height: width * Bomb.heightRatio, alignment: .topLeading)
        }
        .allowsHitTesting(false)
        .task {
            start = .now
            try? await Task.sleep(for: .seconds(duration))
            onFinished()
        }
    }

    private func fall(_ velocity: CGVector, _ t: Double) -> CGSize {
        CGSize(width: velocity.dx * t * width, height: (velocity.dy * t + 0.5 * gravity * t * t) * width)
    }

    private func shardView(_ shard: Shard, _ t: Double) -> some View {
        let move = fall(shard.velocity, t)
        return Image("PotatoReal")
            .resizable()
            .frame(width: width, height: width * Bomb.potatoRatio)
            .overlay {
                ShardShape(points: shard.points)
                    .stroke(Bomb.flesh, lineWidth: width * 0.022)
                    .mask(Image("PotatoReal").resizable())
            }
            .clipShape(ShardShape(points: shard.points))
            .rotationEffect(.degrees(shard.spin * t), anchor: UnitPoint(x: shard.centroid.x, y: shard.centroid.y))
            .scaleEffect(1 - 0.15 * t / duration)
            .offset(move)
            .opacity(1 - Bomb.smoothstep(0.85, duration, t))
            .position(x: width / 2, y: Bomb.potatoCenterY * width)
    }

    private func stick(_ t: Double) -> some View {
        let move = fall(CGVector(dx: 0.9, dy: -2.1), t)
        return DynamiteStick(width: width)
            .rotationEffect(.degrees(540 * t))
            .offset(move)
            .opacity(1 - Bomb.smoothstep(0.9, duration, t))
            .position(x: Bomb.stickCenter.x * width, y: Bomb.stickCenter.y * width)
    }

    private func flash(_ t: Double) -> some View {
        let grow = min(t / 0.3, 1)
        return ZStack {
            StarburstShape(points: 12, innerRatio: 0.55, irregular: true)
                .fill(Theme.orange)
                .frame(width: width * 1.3, height: width * 1.3)
                .scaleEffect(0.3 + 0.8 * grow)
                .opacity(1 - Bomb.smoothstep(0.1, 0.3, t))
            Circle()
                .fill(RadialGradient(colors: [.white, Theme.yellow, Theme.orange.opacity(0.6), .clear], center: .center, startRadius: 0, endRadius: width))
                .frame(width: width * 2, height: width * 2)
                .scaleEffect(0.2 + 0.9 * grow)
                .opacity(1 - Bomb.smoothstep(0.08, 0.38, t))
        }
        .position(x: width / 2, y: Bomb.potatoCenterY * width - width * 0.05)
    }

    private func smoke(_ t: Double) -> some View {
        let spread = 1 - pow(1 - min(t / 1.2, 1), 3)
        return ZStack {
            ForEach(0..<puffCount, id: \.self) { i in
                let angle = Double(i) / Double(puffCount) * 2 * .pi + 0.3
                let size = width * (0.14 + 0.24 * spread)
                Circle()
                    .fill(Bomb.smoke)
                    .frame(width: size, height: size)
                    .blur(radius: width * 0.03)
                    .offset(x: cos(angle) * width * 0.45 * spread, y: sin(angle) * width * 0.35 * spread - width * 0.15 * spread)
            }
        }
        .opacity(0.5 * Bomb.smoothstep(0, 0.12, t) * (1 - Bomb.smoothstep(0.5, duration, t)))
        .position(x: width / 2, y: Bomb.potatoCenterY * width)
    }

    private func bitView(_ bit: Bit, _ t: Double) -> some View {
        let move = fall(bit.velocity, t)
        return RoundedRectangle(cornerRadius: width * 0.005)
            .fill(bit.color)
            .frame(width: width * bit.size, height: width * bit.size * 0.7)
            .rotationEffect(.degrees(bit.spin * t))
            .offset(move)
            .opacity(1 - Bomb.smoothstep(0.8, duration, t))
            .position(x: width / 2, y: Bomb.potatoCenterY * width)
    }
}

private struct ShardShape: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addLines(points.map { CGPoint(x: rect.minX + $0.x * rect.width, y: rect.minY + $0.y * rect.height) })
        path.closeSubpath()
        return path
    }
}

private struct Shard: Identifiable {
    let id: Int
    let points: [CGPoint]
    let centroid: CGPoint
    let velocity: CGVector
    let spin: Double

    static func make() -> [Shard] {
        let center = CGPoint(x: 0.5 + .random(in: -0.06...0.06), y: 0.55 + .random(in: -0.06...0.06))
        let count = Int.random(in: 9...11)
        let offset = Double.random(in: 0..<(2 * .pi))
        let angles = (0..<count).map { offset + (Double($0) + .random(in: -0.3...0.3)) / Double(count) * 2 * .pi }
        let rays = angles.map { angle in
            [0.3, 0.6, 1.4].map { r in
                let a = angle + (r < 1 ? Double.random(in: -0.18...0.18) : 0)
                return CGPoint(x: center.x + cos(a) * r * 0.5, y: center.y + sin(a) * r * 0.5)
            }
        }
        return (0..<count).map { i in
            let next = (i + 1) % count
            let mid = (angles[i] + angles[next] + (next == 0 ? 2 * .pi : 0)) / 2
            let direction = CGVector(dx: cos(mid), dy: sin(mid))
            let speed = Double.random(in: 1.3...2.3)
            return Shard(
                id: i,
                points: [center] + rays[i] + rays[next].reversed(),
                centroid: CGPoint(x: center.x + cos(mid) * 0.22, y: center.y + sin(mid) * 0.22),
                velocity: CGVector(dx: direction.dx * speed, dy: direction.dy * speed - .random(in: 0.8...1.5)),
                spin: .random(in: -600...600)
            )
        }
    }
}

private struct Bit: Identifiable {
    let id: Int
    let color: Color
    let size: CGFloat
    let velocity: CGVector
    let spin: Double

    static func make() -> [Bit] {
        let colors = [Color(hex: 0xA87A45), Bomb.flesh, Color(hex: 0x5A4030)]
        return (0..<22).map { i in
            let angle = Double.random(in: 0..<(2 * .pi))
            let speed = Double.random(in: 1.5...3.2)
            return Bit(
                id: i,
                color: colors[i % colors.count],
                size: .random(in: 0.012...0.03),
                velocity: CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed - .random(in: 0.6...1.4)),
                spin: .random(in: -720...720)
            )
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        PotatoBomb(width: 220, lit: true, shake: 0.3)
        PotatoShatter(width: 220)
    }
    .padding()
    .background(Color(hex: 0xF4EBD9))
}
