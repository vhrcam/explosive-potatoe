import SwiftUI

struct FillBucketGame: View {
    let onComplete: () -> Void

    @State private var level = 0.0
    @State private var pourUntil = Date.distantPast
    @State private var pours = 0
    @State private var isComplete = false

    private let pourAmount = 0.08
    private let drainPerSecond = 0.15
    private let fullLevel = 0.9
    private let drainStep = 0.05
    private let streamTime = 0.25

    var body: some View {
        VStack(spacing: 16) {
            if isComplete {
                MinigameTitle(label: MinigameFX.completeLabel, labelColor: Theme.green, title: "Bucket full!")
            } else {
                MinigameTitle(title: "Fill the Bucket!", subtitle: "Tap fast to pour. Get it past the green line before it leaks out.")
            }

            ZStack {
                TimelineView(.animation(paused: isComplete)) { context in
                    BucketScene(
                        level: level,
                        fullLevel: fullLevel,
                        pouring: context.date < pourUntil,
                        isComplete: isComplete,
                        time: context.date.timeIntervalSinceReferenceDate
                    )
                }
                .keyframeAnimator(initialValue: 1.0, trigger: pours) { view, scale in
                    view.scaleEffect(x: 1 / scale, y: scale, anchor: .bottom)
                } keyframes: { _ in
                    SpringKeyframe(1.035, duration: 0.06)
                    SpringKeyframe(1.0, duration: 0.25, spring: .bouncy)
                }

                if isComplete {
                    WinPop(size: 110)
                        .offset(y: 70)
                }
            }
            .frame(width: 329, height: 400)
            .contentShape(Rectangle())
            .onTapGesture {
                Haptics.tap()
                pour()
            }

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
        guard !isComplete else { return }
        pourUntil = .now.addingTimeInterval(streamTime)
        pours += 1
        SFX.play(.splash, pitch: Float(0.85 + level * 0.7))
        withAnimation(.easeOut(duration: 0.15)) {
            level = min(level + pourAmount, 1)
        }
        if level >= fullLevel {
            MinigameFX.win()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { isComplete = true }
        }
    }

    private func drain() async {
        while !Task.isCancelled && !isComplete {
            try? await Task.sleep(for: .seconds(drainStep))
            if !isComplete {
                level = max(level - drainPerSecond * drainStep, 0)
            }
        }
    }
}

private struct BucketScene: View {
    let level: Double
    let fullLevel: Double
    let pouring: Bool
    let isComplete: Bool
    let time: Double

    private let bottom: CGFloat = 388
    private let top: CGFloat = 180
    private let bubbleCount = 8

    private var waterTop: CGFloat { bottom - CGFloat(level) * (bottom - top) }
    private var fullLineY: CGFloat { bottom - CGFloat(fullLevel) * (bottom - top) }
    private var reachedLine: Bool { level >= fullLevel }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Canvas { context, _ in
                draw(&context)
            }

            if !isComplete {
                Text("FULL")
                    .font(.fredoka(12, .bold))
                    .tracking(1)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Theme.greenGradient))
                    .shadow(color: Theme.shadow, radius: 2, y: 1)
                    .position(x: 298, y: fullLineY)

                Text("\(Int(level * 100))%")
                    .font(.lilita(46))
                    .foregroundStyle(level > 0.33 ? .white : Theme.ink)
                    .shadow(color: Theme.ink.opacity(level > 0.33 ? 0.35 : 0), radius: 0, y: 2)
                    .monospacedDigit()
                    .contentTransition(.numericText(value: level))
                    .position(x: 165, y: 330)
            }
        }
    }

    private func draw(_ context: inout GraphicsContext) {
        let steel = Gradient(colors: [Color(hex: 0xD5DCE4), Color(hex: 0x6F7B89)])

        var shadow = context
        shadow.addFilter(.blur(radius: 8))
        shadow.fill(Path(ellipseIn: CGRect(x: 75, y: 380, width: 180, height: 22)), with: .color(.black.opacity(0.18)))

        if !isComplete {
            let pipe = Path(roundedRect: CGRect(x: -20, y: 18, width: 200, height: 26), cornerRadius: 6)
            context.fill(pipe, with: .linearGradient(steel, startPoint: CGPoint(x: 0, y: 18), endPoint: CGPoint(x: 0, y: 44)))
            let handle = Path(roundedRect: CGRect(x: 70, y: 2, width: 44, height: 14), cornerRadius: 5)
            context.fill(handle, with: .linearGradient(Gradient(colors: [Color(hex: 0xFF8A3D), Color(hex: 0xFF4B2B)]), startPoint: CGPoint(x: 0, y: 2), endPoint: CGPoint(x: 0, y: 16)))
            let spout = Path(roundedRect: CGRect(x: 148, y: 18, width: 38, height: 62), cornerRadius: 9)
            context.fill(spout, with: .linearGradient(steel, startPoint: CGPoint(x: 148, y: 0), endPoint: CGPoint(x: 186, y: 0)))
            context.stroke(pipe, with: .color(Theme.ink.opacity(0.25)), lineWidth: 1)
            context.stroke(spout, with: .color(Theme.ink.opacity(0.25)), lineWidth: 1)
        }

        var handleArc = Path()
        handleArc.move(to: CGPoint(x: 78, y: 172))
        handleArc.addCurve(to: CGPoint(x: 252, y: 172), control1: CGPoint(x: 78, y: 92), control2: CGPoint(x: 252, y: 92))
        context.stroke(handleArc, with: .color(Color(hex: 0x7C8794)), style: StrokeStyle(lineWidth: 4, lineCap: .round))

        var body = Path()
        body.move(to: CGPoint(x: 65, y: 170))
        body.addLine(to: CGPoint(x: 265, y: 170))
        body.addLine(to: CGPoint(x: 253, y: bottom))
        body.addLine(to: CGPoint(x: 77, y: bottom))
        body.closeSubpath()
        context.fill(body, with: .color(.white.opacity(0.45)))

        var water = context
        water.clip(to: body)
        let swell = pouring ? 5.0 : 2.5
        var wave = Path()
        wave.move(to: CGPoint(x: 60, y: bottom + 4))
        for x in stride(from: 60.0, through: 270.0, by: 5) {
            let y = waterTop + CGFloat(sin(x * 0.05 + time * 4) * swell + sin(x * 0.09 - time * 2.6) * swell * 0.6)
            wave.addLine(to: CGPoint(x: x, y: level > 0.01 ? y : bottom + 4))
        }
        wave.addLine(to: CGPoint(x: 270, y: bottom + 4))
        wave.closeSubpath()
        water.fill(wave, with: .linearGradient(
            Gradient(colors: [reachedLine ? Color(hex: 0x6FF0C0) : Color(hex: 0x7CC0FF), Color(hex: 0x2F6FE0)]),
            startPoint: CGPoint(x: 0, y: waterTop),
            endPoint: CGPoint(x: 0, y: bottom)
        ))

        if level > 0.05 {
            for i in 0..<bubbleCount {
                let seed = Double(i) + 1
                let rise = (time * (0.25 + unit(seed * 3.3) * 0.35) + unit(seed * 1.7)).truncatingRemainder(dividingBy: 1)
                let y = bottom - CGFloat(rise) * (bottom - waterTop)
                let x = 85 + CGFloat(unit(seed * 5.9)) * 160 + CGFloat(sin(time * 3 + seed)) * 4
                let r = 2 + CGFloat(unit(seed * 7.1)) * 3
                water.stroke(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(.white.opacity(0.5)), lineWidth: 1.2)
            }
        }

        let gloss = Path(roundedRect: CGRect(x: 82, y: 186, width: 10, height: 170), cornerRadius: 5)
        context.fill(gloss, with: .color(.white.opacity(0.5)))

        if !isComplete {
            var line = Path()
            line.move(to: CGPoint(x: 70, y: fullLineY))
            line.addLine(to: CGPoint(x: 260, y: fullLineY))
            context.stroke(line, with: .color(Theme.green.opacity(0.15)), lineWidth: 8)
            context.stroke(line, with: .color(Theme.green), style: StrokeStyle(lineWidth: 2.5, dash: [9, 6]))
        }

        context.stroke(body, with: .color(Theme.ink.opacity(0.35)), style: StrokeStyle(lineWidth: 1.5, lineJoin: .round))

        let rim = Path(roundedRect: CGRect(x: 57, y: 162, width: 216, height: 16), cornerRadius: 8)
        context.fill(rim, with: .linearGradient(steel, startPoint: CGPoint(x: 0, y: 162), endPoint: CGPoint(x: 0, y: 178)))

        if pouring && !isComplete {
            let wobble = CGFloat(sin(time * 40)) * 1.5
            let stream = Path(roundedRect: CGRect(x: 158 + wobble, y: 76, width: 18, height: max(waterTop - 72, 10)), cornerRadius: 9)
            context.fill(stream, with: .linearGradient(
                Gradient(colors: [Color(hex: 0x9CD0FF), Theme.blue]),
                startPoint: CGPoint(x: 158, y: 0),
                endPoint: CGPoint(x: 176, y: 0)
            ))
            for i in 0..<5 {
                let seed = Double(i) + time * 8
                let dx = CGFloat(sin(seed * 2.1)) * 26
                let dy = CGFloat(abs(sin(seed * 1.3))) * 14
                let r: CGFloat = 3 + CGFloat(i % 2) * 2
                context.fill(Path(ellipseIn: CGRect(x: 167 + dx - r, y: waterTop - 6 - dy - r, width: r * 2, height: r * 2)), with: .color(Color(hex: 0x9CD0FF).opacity(0.85)))
            }
        }
    }

    private func unit(_ seed: Double) -> Double {
        let value = sin(seed * 12.9898) * 43758.5453
        return value - value.rounded(.down)
    }
}

#Preview {
    FillBucketGame(onComplete: {})
        .screen()
}
