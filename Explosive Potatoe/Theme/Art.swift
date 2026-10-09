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

    var body: some View {
        SparkleShape()
            .fill(fill)
            .overlay(SparkleShape().stroke(Theme.ink, lineWidth: 2))
            .frame(width: size, height: size)
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
            context.fill(star, with: .color(Theme.spark))
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

    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.ink)
                .offset(y: size * 0.06)
            Circle()
                .fill(isCheck ? Theme.green : Theme.red)
            Circle()
                .strokeBorder(Theme.ink, lineWidth: max(2, size * 0.06))
            Group {
                if isCheck {
                    CheckShape().stroke(.white, style: StrokeStyle(lineWidth: size * 0.12, lineCap: .round, lineJoin: .round))
                } else {
                    CrossShape().stroke(.white, style: StrokeStyle(lineWidth: size * 0.12, lineCap: .round))
                }
            }
            .padding(size * (isCheck ? 0.27 : 0.32))
        }
        .frame(width: size, height: size)
    }
}

struct CrateView: View {
    let colorIndex: Int
    var size: CGFloat = 66

    var body: some View {
        let dark = Theme.crateDark[colorIndex]
        let inset = size * 0.13
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.1)
                .fill(Theme.crateColors[colorIndex])
            RoundedRectangle(cornerRadius: size * 0.05)
                .stroke(dark, lineWidth: size * 0.05)
                .padding(inset)
            CrossShape()
                .stroke(dark, lineWidth: size * 0.05)
                .padding(inset)
            RoundedRectangle(cornerRadius: size * 0.1)
                .strokeBorder(Theme.ink, lineWidth: 3)
        }
        .frame(width: size, height: size)
    }
}

private struct BinBodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.1, y: rect.maxY - 4))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.1, y: rect.maxY - 4),
            control: CGPoint(x: rect.midX, y: rect.maxY + 4)
        )
        path.closeSubpath()
        return path
    }
}

struct BinView: View {
    let colorIndex: Int

    var body: some View {
        let dark = Theme.crateDark[colorIndex]
        ZStack(alignment: .top) {
            ZStack {
                BinBodyShape().fill(Theme.crateColors[colorIndex])
                VStack(spacing: 18) {
                    Capsule().fill(dark).frame(width: 56, height: 3)
                    Capsule().fill(dark).frame(width: 52, height: 3)
                }
                .offset(y: 4)
                BinBodyShape().stroke(Theme.ink, style: StrokeStyle(lineWidth: 3, lineJoin: .round))
            }
            .frame(width: 88, height: 100)
            .offset(y: 12)

            RoundedRectangle(cornerRadius: 5)
                .fill(dark)
                .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(Theme.ink, lineWidth: 3))
                .frame(width: 100, height: 17)
        }
        .frame(width: 100, height: 112, alignment: .top)
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
            context.fill(crown, with: .color(.white))
            context.stroke(crown, with: .color(Theme.ink), style: StrokeStyle(lineWidth: 4 * s, lineJoin: .round))

            let band = Path(roundedRect: CGRect(x: 6 * s, y: 40 * s, width: 64 * s, height: 11 * s), cornerRadius: 2 * s)
            context.fill(band, with: .color(Theme.red))
            context.stroke(band, with: .color(Theme.ink), lineWidth: 4 * s)

            for point in [CGPoint(x: 6, y: 10), CGPoint(x: 38, y: 5), CGPoint(x: 70, y: 10)] {
                let ball = Path(ellipseIn: CGRect(x: (point.x - 5) * s, y: (point.y - 5) * s, width: 10 * s, height: 10 * s))
                context.fill(ball, with: .color(Theme.red))
                context.stroke(ball, with: .color(Theme.ink), lineWidth: 3 * s)
            }
        }
        .frame(width: 76, height: 54)
    }
}

struct ExplosionIcon: View {
    var size: CGFloat = 18

    var body: some View {
        ZStack {
            StarburstShape(points: 9, innerRatio: 0.6).fill(Theme.red)
            StarburstShape(points: 9, innerRatio: 0.6).stroke(Theme.ink, lineWidth: 1.5)
            Circle().fill(Theme.yellow).padding(size * 0.32)
        }
        .frame(width: size, height: size)
    }
}

struct ShakeLines: View {
    var flipped = false

    var body: some View {
        VStack(spacing: 14) {
            Capsule().frame(width: 26, height: 4).rotationEffect(.degrees(flipped ? 15 : -15))
            Capsule().frame(width: 30, height: 4)
            Capsule().frame(width: 26, height: 4).rotationEffect(.degrees(flipped ? -15 : 15))
        }
        .foregroundStyle(Theme.ink)
    }
}
