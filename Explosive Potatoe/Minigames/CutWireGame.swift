import SwiftUI

private enum Wire: CaseIterable {
    case red, blue, green, yellow, purple, pink

    var color: Color {
        switch self {
        case .red: Theme.fire
        case .blue: Theme.blue
        case .green: Theme.green
        case .yellow: Theme.yellow
        case .purple: Theme.purple
        case .pink: Theme.pink
        }
    }

    var name: String { "\(self)".uppercased() }

    static func board() -> [Wire] {
        Array(allCases.shuffled().prefix(Int.random(in: 4...5)))
    }
}

struct CutWireGame: View {
    let onComplete: () -> Void

    @State private var wires = Wire.board()
    @State private var target = Wire.red
    @State private var board = 0
    @State private var cutAt: [Int: CGFloat] = [:]
    @State private var wrongWire: Int?
    @State private var streak = 0
    @State private var misses = 0
    @State private var locked = false
    @State private var trail: [CGPoint] = []
    @State private var trailOpacity = 1.0
    @State private var isSwiping = false
    @State private var didCut = false
    @State private var spark: (point: CGPoint, id: Int)?
    @State private var isComplete = false

    private let goal = 3
    private let panel = CGSize(width: 329, height: 290)
    private let wireLeft: CGFloat = 50
    private let wireRight: CGFloat = 279
    private let wirePad: CGFloat = 34
    private let wave: CGFloat = 7
    private let cutGap: CGFloat = 9
    private let droop: CGFloat = 16
    private let trailLength = 18
    private let nextBoardDelay = 0.55
    private let wrongDelay = 0.9

    var body: some View {
        VStack(spacing: 16) {
            header
            sign
            stage
            if isComplete {
                CompleteFooter(onDone: onComplete)
            } else {
                Spacer(minLength: 0)
                FuseWarning()
            }
        }
        .onAppear { target = wires.randomElement() ?? .red }
    }

    @ViewBuilder
    private var header: some View {
        if isComplete {
            MinigameTitle(label: MinigameFX.completeLabel, labelColor: Theme.green, title: "Bomb defused!")
        } else if wrongWire != nil {
            MinigameTitle(label: "Wrong wire · streak reset", labelColor: Theme.fire, title: "Zap! Wrong one", subtitle: "Swipe through the right wire, \(goal) in a row.")
        } else {
            MinigameTitle(title: "Cut the Wire", subtitle: "Swipe through the right wire, \(goal) in a row.")
        }
    }

    private var sign: some View {
        HStack(spacing: 14) {
            Image(systemName: "scissors")
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(target.color)
                .shadow(color: Theme.shadow, radius: 1, y: 1)
            VStack(alignment: .leading, spacing: 0) {
                Text("CUT THE")
                    .font(.fredoka(13, .bold))
                    .tracking(1.6)
                    .foregroundStyle(Theme.textDim)
                Text("\(target.name) WIRE")
                    .font(.lilita(34))
                    .foregroundStyle(target.color)
                    .shadow(color: Theme.ink.opacity(0.25), radius: 0, y: 2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .id(board)
            .transition(.push(from: .bottom))
            Spacer(minLength: 0)
            StreakPips(value: streak, total: goal)
        }
        .glassCard(cornerRadius: 22, padding: 16)
        .clipped()
    }

    private var stage: some View {
        let shape = RoundedRectangle(cornerRadius: 26, style: .continuous)
        return ZStack(alignment: .topLeading) {
            shape.fill(Color(hex: 0x3A332C))

            Canvas { context, size in
                drawFrame(&context, size: size)
                for i in wires.indices {
                    drawWire(&context, index: i)
                }
            }
            .id(board)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))

            Canvas { context, _ in
                guard trail.count > 1 else { return }
                var path = Path()
                path.addLines(trail)
                context.stroke(path, with: .color(.white.opacity(0.25)), style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round))
                context.stroke(path, with: .color(.white), style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
            }
            .opacity(trailOpacity)
            .allowsHitTesting(false)

            if let spark {
                Burst(colors: [Theme.yellow, Theme.orange, .white], count: 12, distance: 46, pieceSize: 9)
                    .id(spark.id)
                    .position(spark.point)
            }

            if let wrongWire, let x = cutAt[wrongWire] {
                MissPop(size: 54)
                    .position(x: x, y: wireY(wrongWire, at: x) - 44)
            }

            if isComplete {
                WinPop(size: 110)
                    .position(x: panel.width / 2, y: panel.height / 2)
            }

            shape.strokeBorder(wrongWire == nil ? Theme.stroke : Theme.fire, lineWidth: wrongWire == nil ? 1 : 3)
                .allowsHitTesting(false)
        }
        .frame(width: panel.width, height: panel.height)
        .clipShape(shape)
        .contentShape(shape)
        .shake(misses)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in swipe(to: value.location) }
                .onEnded { _ in endSwipe() }
        )
        .allowsHitTesting(!isComplete)
    }

    private func wireY(_ index: Int, at x: CGFloat) -> CGFloat {
        let spacing = (panel.height - wirePad * 2) / CGFloat(wires.count)
        let base = wirePad + (CGFloat(index) + 0.5) * spacing
        let t = Double((x - wireLeft) / (wireRight - wireLeft))
        return base + wave * CGFloat(sin(t * .pi * 2 + Double(index) * 1.7 + Double(board) * 0.9))
    }

    private func drawFrame(_ context: inout GraphicsContext, size: CGSize) {
        var stripes = context
        stripes.clip(to: Path(CGRect(x: 0, y: 0, width: size.width, height: 10)))
        stripes.fill(Path(CGRect(x: 0, y: 0, width: size.width, height: 10)), with: .color(Theme.yellow.opacity(0.85)))
        for x in stride(from: -10.0, through: size.width, by: 22) {
            var stripe = Path()
            stripe.move(to: CGPoint(x: x, y: 10))
            stripe.addLine(to: CGPoint(x: x + 10, y: 0))
            stripe.addLine(to: CGPoint(x: x + 21, y: 0))
            stripe.addLine(to: CGPoint(x: x + 11, y: 10))
            stripe.closeSubpath()
            stripes.fill(stripe, with: .color(.black.opacity(0.8)))
        }

        let steel = Gradient(colors: [Color(hex: 0xD5DCE4), Color(hex: 0x6F7B89)])
        for x in [wireLeft - 26, wireRight + 4] {
            let block = Path(roundedRect: CGRect(x: x, y: wirePad - 8, width: 22, height: panel.height - wirePad * 2 + 16), cornerRadius: 8)
            context.fill(block, with: .color(.white.opacity(0.1)))
            context.stroke(block, with: .color(.white.opacity(0.18)), lineWidth: 1)
        }
        for i in wires.indices {
            for x in [wireLeft - 15, wireRight + 15] {
                let y = wireY(i, at: x < panel.width / 2 ? wireLeft : wireRight)
                let screw = Path(ellipseIn: CGRect(x: x - 7, y: y - 7, width: 14, height: 14))
                context.fill(screw, with: .linearGradient(steel, startPoint: CGPoint(x: x, y: y - 7), endPoint: CGPoint(x: x, y: y + 7)))
                var slot = Path()
                slot.move(to: CGPoint(x: x - 4, y: y + 2))
                slot.addLine(to: CGPoint(x: x + 4, y: y - 2))
                context.stroke(slot, with: .color(.black.opacity(0.5)), lineWidth: 1.5)
            }
        }
    }

    private func drawWire(_ context: inout GraphicsContext, index: Int) {
        let color = wires[index].color
        var pieces: [Path] = []
        var tips: [CGPoint] = []

        if let x = cutAt[index] {
            let left = x - cutGap
            let right = x + cutGap
            pieces.append(wirePath(index, from: wireLeft, to: left) { px in droop * pow(max(0, (px - (left - 36)) / 36), 2) })
            pieces.append(wirePath(index, from: right, to: wireRight) { px in droop * pow(max(0, ((right + 36) - px) / 36), 2) })
            tips = [CGPoint(x: left, y: wireY(index, at: left) + droop), CGPoint(x: right, y: wireY(index, at: right) + droop)]
        } else {
            pieces.append(wirePath(index, from: wireLeft, to: wireRight) { _ in 0 })
        }

        for piece in pieces {
            context.stroke(piece, with: .color(.black.opacity(0.45)), style: StrokeStyle(lineWidth: 17, lineCap: .round, lineJoin: .round))
            context.stroke(piece, with: .color(color), style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round))
            context.stroke(piece.offsetBy(dx: 0, dy: -3), with: .color(.white.opacity(0.35)), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
        }
        for tip in tips {
            context.fill(Path(ellipseIn: CGRect(x: tip.x - 5, y: tip.y - 5, width: 10, height: 10)), with: .color(Theme.orange))
            context.fill(Path(ellipseIn: CGRect(x: tip.x - 2.5, y: tip.y - 2.5, width: 5, height: 5)), with: .color(Theme.yellow))
        }
    }

    private func wirePath(_ index: Int, from start: CGFloat, to end: CGFloat, sag: (CGFloat) -> CGFloat) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: start, y: wireY(index, at: start) + sag(start)))
        for x in stride(from: start, through: end, by: 4) {
            path.addLine(to: CGPoint(x: x, y: wireY(index, at: x) + sag(x)))
        }
        path.addLine(to: CGPoint(x: end, y: wireY(index, at: end) + sag(end)))
        return path
    }

    private func swipe(to point: CGPoint) {
        if !isSwiping {
            isSwiping = true
            didCut = false
            trail = [point]
            trailOpacity = 1
            return
        }
        guard let previous = trail.last else { return }
        trail.append(point)
        if trail.count > trailLength { trail.removeFirst() }
        guard !locked, !didCut else { return }

        let crossings = wires.indices.compactMap { i -> (index: Int, x: CGFloat, distance: CGFloat)? in
            guard cutAt[i] == nil else { return nil }
            let before = previous.y - wireY(i, at: previous.x)
            let after = point.y - wireY(i, at: point.x)
            guard before * after <= 0, before != after else { return nil }
            let x = previous.x + (point.x - previous.x) * before / (before - after)
            guard x > wireLeft + 12, x < wireRight - 12 else { return nil }
            return (i, x, abs(before))
        }
        if let first = crossings.min(by: { $0.distance < $1.distance }) {
            cut(first.index, at: first.x)
        }
    }

    private func endSwipe() {
        isSwiping = false
        withAnimation(.easeOut(duration: 0.3)) { trailOpacity = 0 }
    }

    private func cut(_ index: Int, at x: CGFloat) {
        didCut = true
        locked = true
        cutAt[index] = x
        spark = (CGPoint(x: x, y: wireY(index, at: x)), (spark?.id ?? 0) + 1)
        SFX.play(.snip)

        if wires[index] == target {
            streak += 1
            if streak >= goal {
                MinigameFX.win()
                Task {
                    try? await Task.sleep(for: .seconds(nextBoardDelay))
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { isComplete = true }
                }
            } else {
                MinigameFX.step(Double(streak) / Double(goal))
                Task {
                    try? await Task.sleep(for: .seconds(nextBoardDelay))
                    newBoard()
                }
            }
        } else {
            streak = 0
            misses += 1
            SFX.play(.zap)
            Haptics.fail()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { wrongWire = index }
            Task {
                try? await Task.sleep(for: .seconds(wrongDelay))
                newBoard()
            }
        }
    }

    private func newBoard() {
        let next = Wire.board()
        SFX.play(.flip)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            board += 1
            wires = next
            target = next.randomElement() ?? .red
            cutAt = [:]
            wrongWire = nil
            spark = nil
            locked = false
        }
    }
}

#Preview {
    CutWireGame(onComplete: {})
        .screen()
}
