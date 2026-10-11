import SwiftUI

struct StarburstShape: Shape {
    var points: Int
    var innerRatio: CGFloat
    var irregular = false

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let wobble: [CGFloat] = [1, 0.84, 0.94, 0.88, 0.97]
        var path = Path()
        for i in 0..<(points * 2) {
            let angle = CGFloat(i) * .pi / CGFloat(points) - .pi / 2
            var radius = i.isMultiple(of: 2) ? outer : outer * innerRatio
            if irregular && i.isMultiple(of: 2) {
                radius *= wobble[(i / 2) % wobble.count]
            }
            let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

struct SparkleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let dx = rect.width * 0.1
        let dy = rect.height * 0.1
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY), control: CGPoint(x: rect.midX + dx, y: rect.midY - dy))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control: CGPoint(x: rect.midX + dx, y: rect.midY + dy))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.midY), control: CGPoint(x: rect.midX - dx, y: rect.midY + dy))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: CGPoint(x: rect.midX - dx, y: rect.midY - dy))
        path.closeSubpath()
        return path
    }
}

struct Sparkle: View {
    var size: CGFloat = 30
    var fill: Color = Theme.yellow
    @State private var twinkle = false

    var body: some View {
        SparkleShape()
            .fill(fill)
            .frame(width: size, height: size)
            .shadow(color: Theme.shadow, radius: 1, y: 1)
            .scaleEffect(twinkle ? 1 : 0.7)
            .rotationEffect(.degrees(twinkle ? 12 : -12))
            .onAppear {
                withAnimation(.easeInOut(duration: Double.random(in: 0.8...1.4)).repeatForever(autoreverses: true)) { twinkle = true }
            }
    }
}

struct FuseIcon: View {
    var size: CGFloat = 18

    var body: some View {
        Canvas { context, canvas in
            var stick = Path()
            stick.move(to: CGPoint(x: canvas.width * 0.12, y: canvas.height * 0.92))
            stick.addQuadCurve(
                to: CGPoint(x: canvas.width * 0.62, y: canvas.height * 0.36),
                control: CGPoint(x: canvas.width * 0.18, y: canvas.height * 0.4)
            )
            context.stroke(stick, with: .color(Theme.yellow), style: StrokeStyle(lineWidth: canvas.width * 0.13, lineCap: .round))
            let star = StarburstShape(points: 6, innerRatio: 0.45)
                .path(in: CGRect(x: canvas.width * 0.46, y: 0, width: canvas.width * 0.54, height: canvas.width * 0.54))
            context.fill(star, with: .color(Theme.orange))
        }
        .frame(width: size, height: size)
    }
}

struct CheckShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.55))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.36, y: rect.minY + rect.height * 0.88))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.15))
        return path
    }
}

struct CrossShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        return path
    }
}

struct ResultBadge: View {
    let isCheck: Bool
    var size: CGFloat = 130
    @State private var drawn = false

    var body: some View {
        ZStack {
            Circle()
                .fill(isCheck ? Theme.greenGradient : Theme.fireGradient)
                .overlay(Circle().strokeBorder(.white.opacity(0.4), lineWidth: max(1.5, size * 0.025)))
                .shadow(color: Theme.shadow, radius: size * 0.06, y: size * 0.04)
            Group {
                if isCheck {
                    CheckShape()
                        .trim(from: 0, to: drawn ? 1 : 0)
                        .stroke(.white, style: StrokeStyle(lineWidth: size * 0.12, lineCap: .round, lineJoin: .round))
                } else {
                    CrossShape()
                        .trim(from: 0, to: drawn ? 1 : 0)
                        .stroke(.white, style: StrokeStyle(lineWidth: size * 0.12, lineCap: .round))
                }
            }
            .padding(size * (isCheck ? 0.27 : 0.32))
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeOut(duration: 0.35).delay(0.08)) { drawn = true }
        }
    }
}

struct CrownView: View {
    var body: some View {
        Canvas { context, size in
            let s = size.width / 76
            var crown = Path()
            crown.move(to: CGPoint(x: 6 * s, y: 40 * s))
            crown.addLine(to: CGPoint(x: 6 * s, y: 14 * s))
            crown.addLine(to: CGPoint(x: 22 * s, y: 27 * s))
            crown.addLine(to: CGPoint(x: 38 * s, y: 8 * s))
            crown.addLine(to: CGPoint(x: 54 * s, y: 27 * s))
            crown.addLine(to: CGPoint(x: 70 * s, y: 14 * s))
            crown.addLine(to: CGPoint(x: 70 * s, y: 40 * s))
            crown.closeSubpath()
            context.fill(crown, with: .linearGradient(
                Gradient(colors: [Color(hex: 0xFFE27A), Color(hex: 0xFFB21F)]),
                startPoint: CGPoint(x: 0, y: 8 * s), endPoint: CGPoint(x: 0, y: 40 * s)
            ))

            let band = Path(roundedRect: CGRect(x: 6 * s, y: 40 * s, width: 64 * s, height: 11 * s), cornerRadius: 2 * s)
            context.fill(band, with: .color(Color(hex: 0xE89A0C)))

            for point in [CGPoint(x: 6, y: 10), CGPoint(x: 38, y: 5), CGPoint(x: 70, y: 10)] {
                let ball = Path(ellipseIn: CGRect(x: (point.x - 5) * s, y: (point.y - 5) * s, width: 10 * s, height: 10 * s))
                context.fill(ball, with: .color(Theme.pink))
            }
            for x in [22.0, 38, 54] {
                let gem = Path(ellipseIn: CGRect(x: (x - 3) * s, y: 42.5 * s, width: 6 * s, height: 6 * s))
                context.fill(gem, with: .color(.white.opacity(0.85)))
            }
        }
        .frame(width: 76, height: 54)
        .shadow(color: Theme.shadow, radius: 3, y: 2)
    }
}

struct ExplosionIcon: View {
    var size: CGFloat = 18

    var body: some View {
        ZStack {
            StarburstShape(points: 9, innerRatio: 0.6).fill(Theme.fire)
            Circle().fill(Theme.yellow).padding(size * 0.32)
        }
        .frame(width: size, height: size)
    }
}

struct ShakeLines: View {
    var flipped = false
    var color: Color = Theme.ink

    var body: some View {
        VStack(spacing: 14) {
            Capsule().frame(width: 22, height: 4).rotationEffect(.degrees(flipped ? 15 : -15))
            Capsule().frame(width: 28, height: 4)
            Capsule().frame(width: 22, height: 4).rotationEffect(.degrees(flipped ? -15 : 15))
        }
        .foregroundStyle(color.opacity(0.8))
    }
}
