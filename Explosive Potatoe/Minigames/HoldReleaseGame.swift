import SwiftUI

struct HoldReleaseGame: View {
    let onComplete: () -> Void

    @State private var holdStart: Date?
    @State private var targetStart = Double.random(in: 0.55...0.8)
    @State private var missText: String?
    @State private var misses = 0
    @State private var needsLift = false
    @State private var isComplete = false

    private let fillTime = 1.6
    private let targetSize = 0.12
    private let ringSize: CGFloat = 250
    private let ringWidth: CGFloat = 26
    private let buttonSize: CGFloat = 150
    private let tickInterval = 0.09

    var body: some View {
        VStack(spacing: 16) {
            header

            ZStack {
                TimelineView(.animation(paused: holdStart == nil)) { context in
                    ring(fill: progress(at: context.date))
                }
                .frame(width: ringSize, height: ringSize)
                .shake(misses)

                if isComplete {
                    WinPop(size: 120)
                } else {
                    holdButton
                }
            }
            .frame(height: ringSize + 70)

            if isComplete {
                CompleteFooter(onDone: onComplete)
            } else {
                Spacer(minLength: 0)
                FuseWarning()
            }
        }
        .task(id: holdStart) { await ticks() }
    }

    @ViewBuilder
    private var header: some View {
        if isComplete {
            MinigameHeader(label: MinigameFX.completeLabel, labelColor: Theme.green, title: "Nailed it!")
        } else if let missText {
            MinigameHeader(label: "Missed · new target", labelColor: Theme.fire, title: missText, subtitle: "Hold the button, let go in the green.")
        } else {
            MinigameHeader(title: "Hold & Release", subtitle: "Hold the button, let go in the green.")
        }
    }

    private func ring(fill: Double) -> some View {
        let inZone = fill >= targetStart && fill <= targetStart + targetSize
        let angle = fill * 2 * .pi
        let radius = ringSize / 2
        return ZStack {
            Circle()
                .stroke(Theme.surfaceStrong, lineWidth: ringWidth)
            Circle()
                .stroke(Theme.stroke, lineWidth: 1)
                .padding(-ringWidth / 2)
            Circle()
                .stroke(Theme.stroke, lineWidth: 1)
                .padding(ringWidth / 2)
            Circle()
                .trim(from: targetStart, to: targetStart + targetSize)
                .stroke(Theme.green.opacity(inZone ? 1 : 0.8), lineWidth: ringWidth)
                .shadow(color: Theme.green.opacity(inZone ? 1 : 0.6), radius: inZone ? 20 : 10)
            Circle()
                .trim(from: 0, to: fill)
                .stroke(
                    AngularGradient(colors: [Theme.yellow, Theme.orange, Theme.fire], center: .center, startAngle: .zero, endAngle: .degrees(360)),
                    style: StrokeStyle(lineWidth: ringWidth * 0.55, lineCap: .round)
                )
                .shadow(color: Theme.fire.opacity(0.7), radius: 10)
            if fill > 0 {
                Circle()
                    .fill(.white)
                    .frame(width: ringWidth * 0.7, height: ringWidth * 0.7)
                    .shadow(color: Theme.yellow, radius: 10)
                    .offset(x: cos(angle) * radius, y: sin(angle) * radius)
            }
        }
        .rotationEffect(.degrees(-90))
        .animation(.spring(response: 0.45, dampingFraction: 0.7), value: targetStart)
    }

    private var holdButton: some View {
        let isHolding = holdStart != nil
        return Text(isHolding ? "…" : "HOLD")
            .font(.lilita(38))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.3), radius: 0, y: 2)
            .frame(width: buttonSize, height: buttonSize)
            .background(Circle().fill(Theme.fireGradient))
            .overlay(
                Circle().strokeBorder(
                    LinearGradient(colors: [.white.opacity(0.6), .white.opacity(0.05)], startPoint: .top, endPoint: .bottom),
                    lineWidth: 1.5
                )
            )
            .background(Circle().fill(Color(hex: 0x9E2A14)).offset(y: isHolding ? 2 : 8))
            .offset(y: isHolding ? 6 : 0)
            .scaleEffect(isHolding ? 0.94 : 1)
            .shadow(color: Theme.fire.opacity(isHolding ? 0.9 : 0.5), radius: isHolding ? 30 : 18, y: 8)
            .animation(.spring(response: 0.22, dampingFraction: 0.6), value: isHolding)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if holdStart == nil && !needsLift { startHold() }
                    }
                    .onEnded { _ in
                        if needsLift {
                            needsLift = false
                        } else {
                            release()
                        }
                    }
            )
    }

    private func progress(at date: Date) -> Double {
        guard let holdStart else { return 0 }
        return min(date.timeIntervalSince(holdStart) / fillTime, 1)
    }

    private func startHold() {
        holdStart = .now
        SFX.play(.grab)
        Haptics.tap()
    }

    private func ticks() async {
        while holdStart != nil && !Task.isCancelled {
            try? await Task.sleep(for: .seconds(tickInterval))
            guard holdStart != nil, !Task.isCancelled else { return }
            let fill = progress(at: .now)
            SFX.play(.tick, pitch: Float(0.8 + fill))
            Haptics.tap()
            if fill >= 1 {
                needsLift = true
                release()
            }
        }
    }

    private func release() {
        guard holdStart != nil else { return }
        let fill = progress(at: .now)
        holdStart = nil
        if fill >= targetStart && fill <= targetStart + targetSize {
            MinigameFX.win()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { isComplete = true }
        } else {
            MinigameFX.miss()
            misses += 1
            missText = fill < targetStart ? "Too early!" : "Too late!"
            targetStart = Double.random(in: 0.55...0.8)
        }
    }
}

#Preview {
    HoldReleaseGame(onComplete: {})
        .screen()
}
