import SwiftUI

struct FillBucketGame: View {
    let onComplete: () -> Void

    @State private var level = 0.0
    @State private var pourUntil = Date.distantPast
    @State private var isComplete = false

    private let pourAmount = 0.08
    private let drainPerSecond = 0.15
    private let fullLevel = 0.9

    var body: some View {
        VStack(spacing: 16) {
            if isComplete {
                MinigameHeader(label: "Minigame complete · +10", labelColor: Theme.green, title: "Bucket full!")
            } else {
                MinigameHeader(title: "Fill the Bucket!", subtitle: "Tap fast to pour. Fill it past the green line.")
            }

            TimelineView(.animation(paused: isComplete)) { context in
                BucketScene(
                    level: level,
                    fullLevel: fullLevel,
                    pouring: context.date < pourUntil,
                    isComplete: isComplete
                )
            }
            .frame(width: 329, height: 400)

            if isComplete {
                CompleteFooter(onDone: onComplete)
            } else {
                Spacer(minLength: 0)
                Button("TAP TAP TAP!", action: pour)
                    .buttonStyle(.chunky(.blue))
            }
        }
        .task { await drain() }
    }

    private func pour() {
        pourUntil = .now.addingTimeInterval(0.25)
        withAnimation(.easeOut(duration: 0.15)) {
            level = min(level + pourAmount, 1)
        }
        if level >= fullLevel {
            withAnimation(.spring(duration: 0.4)) { isComplete = true }
        }
    }

    private func drain() async {
        while !Task.isCancelled && !isComplete {
            try? await Task.sleep(for: .milliseconds(50))
            if !isComplete {
                level = max(level - drainPerSecond * 0.05, 0)
            }
        }
    }
}

private struct BucketScene: View {
    let level: Double
    let fullLevel: Double
    let pouring: Bool
    let isComplete: Bool

    private let bottom: CGFloat = 388
    private let top: CGFloat = 180

    private var waterTop: CGFloat { bottom - CGFloat(level) * (bottom - top) }
    private var fullLineY: CGFloat { bottom - CGFloat(fullLevel) * (bottom - top) }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Canvas { context, _ in
                draw(&context)
            }

            if isComplete {
                ResultBadge(isCheck: true, size: 120)
                    .position(x: 165, y: 255)
                Sparkle(size: 28).position(x: 54, y: 104)
                Sparkle(size: 36).position(x: 308, y: 138)
                Sparkle(size: 22).position(x: 72, y: 312)
                Sparkle(size: 30).position(x: 296, y: 336)
            } else {
                Text("FULL")
                    .font(.fredoka(12, .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Theme.green))
                    .overlay(Capsule().strokeBorder(Theme.ink, lineWidth: 2))
                    .position(x: 295, y: fullLineY)

                Text("\(Int(level * 100))%")
                    .font(.lilita(44))
                    .foregroundStyle(.white)
                    .shadow(color: Theme.ink, radius: 0, x: 0, y: 3)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .position(x: 165, y: 340)
            }
        }
    }

    private func draw(_ context: inout GraphicsContext) {
        let steel = Color(hex: 0xB8C0CA)

        context.fill(Path(ellipseIn: CGRect(x: 70, y: 378, width: 190, height: 24)), with: .color(Theme.ink.opacity(0.12)))

        if !isComplete {
            let pipe = Path(roundedRect: CGRect(x: -20, y: 18, width: 200, height: 26), cornerRadius: 4)
            context.fill(pipe, with: .color(steel))
            context.stroke(pipe, with: .color(Theme.ink), lineWidth: 3)
            let handle = Path(roundedRect: CGRect(x: 70, y: 2, width: 44, height: 14), cornerRadius: 4)
            context.fill(handle, with: .color(Theme.red))
            context.stroke(handle, with: .color(Theme.ink), lineWidth: 3)
            let spout = Path(roundedRect: CGRect(x: 148, y: 18, width: 38, height: 62), cornerRadius: 8)
            context.fill(spout, with: .color(steel))
            context.stroke(spout, with: .color(Theme.ink), lineWidth: 3)
        }

        var handleArc = Path()
        handleArc.move(to: CGPoint(x: 78, y: 172))
        handleArc.addCurve(to: CGPoint(x: 252, y: 172), control1: CGPoint(x: 78, y: 92), control2: CGPoint(x: 252, y: 92))
        context.stroke(handleArc, with: .color(Theme.ink), lineWidth: 5)

        var body = Path()
        body.move(to: CGPoint(x: 65, y: 170))
        body.addLine(to: CGPoint(x: 265, y: 170))
        body.addLine(to: CGPoint(x: 253, y: bottom))
        body.addLine(to: CGPoint(x: 77, y: bottom))
        body.closeSubpath()
        context.fill(body, with: .color(Color(hex: 0xEEF3F7)))

        var water = context
        water.clip(to: body)
        water.fill(Path(CGRect(x: 60, y: waterTop, width: 210, height: bottom - waterTop + 4)), with: .color(Theme.blue))
        water.fill(Path(CGRect(x: 60, y: waterTop, width: 210, height: 10)), with: .color(Color(hex: 0x86BDEE)))
        for y in [262.0, 328.0] {
            var ridge = Path()
            ridge.move(to: CGPoint(x: 68, y: y))
            ridge.addLine(to: CGPoint(x: 262, y: y))
            water.stroke(ridge, with: .color(Theme.ink.opacity(0.15)), lineWidth: 2)
        }

        if !isComplete {
            var line = Path()
            line.move(to: CGPoint(x: 70, y: fullLineY))
            line.addLine(to: CGPoint(x: 260, y: fullLineY))
            context.stroke(line, with: .color(Theme.green), style: StrokeStyle(lineWidth: 3, dash: [9, 6]))
        }

        context.stroke(body, with: .color(Theme.ink), style: StrokeStyle(lineWidth: 5, lineJoin: .round))

        let rim = Path(roundedRect: CGRect(x: 57, y: 162, width: 216, height: 16), cornerRadius: 6)
        context.fill(rim, with: .color(steel))
        context.stroke(rim, with: .color(Theme.ink), lineWidth: 4)

        if pouring && !isComplete {
            let stream = Path(roundedRect: CGRect(x: 157, y: 76, width: 20, height: max(waterTop - 70, 10)), cornerRadius: 10)
            context.fill(stream, with: .color(Theme.blue))
            context.stroke(stream, with: .color(Theme.blueShadow), lineWidth: 2)
        }
    }
}

#Preview {
    FillBucketGame(onComplete: {})
        .screen()
}
