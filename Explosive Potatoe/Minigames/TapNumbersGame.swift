import SwiftUI

struct TapNumbersGame: View {
    let onComplete: () -> Void

    @State private var numbers = Array(1...9).shuffled()
    @State private var next = 1
    @State private var wrongTile: Int?
    @State private var needed = 1
    @State private var misses = 0

    private let tileSize: CGFloat = 94
    private let spacing: CGFloat = 14
    private let reshuffleDelay = 0.9
    private var isComplete: Bool { next > numbers.count }

    var body: some View {
        VStack(spacing: 16) {
            header

            ProgressBarView(
                value: wrongTile == nil ? next - 1 : 0,
                total: numbers.count,
                fill: wrongTile == nil ? Theme.green : Theme.fire,
                labelColor: wrongTile == nil ? Theme.text : Theme.fire
            )

            ZStack {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(tileSize), spacing: spacing), count: 3), spacing: spacing) {
                    ForEach(numbers, id: \.self) { number in
                        NumberTile(number: number, look: look(number), size: tileSize) { tap(number) }
                            .disabled(wrongTile != nil || isComplete)
                    }
                }
                .shake(misses)

                if wrongTile != nil {
                    MissPop(size: 110)
                }
                if isComplete {
                    WinPop(size: 116)
                }
            }
            .frame(height: tileSize * 3 + spacing * 2 + 12)

            if isComplete {
                CompleteFooter(onDone: onComplete)
            } else {
                Spacer(minLength: 0)
                FuseWarning()
            }
        }
    }

    @ViewBuilder
    private var header: some View {
        if isComplete {
            MinigameHeader(label: MinigameFX.completeLabel, labelColor: Theme.green, title: "All 9!")
        } else if let wrongTile {
            MinigameHeader(
                label: "Wrong tile · reshuffling",
                labelColor: Theme.fire,
                title: "Oops! That's \(wrongTile)",
                subtitle: "You needed \(needed). The board reshuffles, start again from 1."
            )
        } else {
            MinigameHeader(title: "Tap 1 → 9", subtitle: "In order, fast. A wrong tap reshuffles the board!")
        }
    }

    private func look(_ number: Int) -> NumberTile.Look {
        if isComplete { return .done }
        if number == wrongTile { return .wrong }
        if wrongTile != nil { return number < next ? .dimDone : .dim }
        return number < next ? .done : .todo
    }

    private func tap(_ number: Int) {
        if number == next {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { next += 1 }
            if isComplete {
                MinigameFX.win()
            } else {
                MinigameFX.step(Double(next - 1) / Double(numbers.count))
            }
        } else if number > next {
            needed = next
            misses += 1
            MinigameFX.miss()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { wrongTile = number }
            Task {
                try? await Task.sleep(for: .seconds(reshuffleDelay))
                SFX.play(.flip)
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    next = 1
                    wrongTile = nil
                    numbers.shuffle()
                }
            }
        }
    }
}

private struct NumberTile: View {
    enum Look { case todo, done, wrong, dim, dimDone }

    let number: Int
    let look: Look
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        Button(action: action) {
            Text("\(number)")
                .font(.lilita(46))
                .foregroundStyle(look == .todo || look == .dim ? Theme.text : .white)
                .shadow(color: .black.opacity(look == .todo ? 0 : 0.25), radius: 0, y: 2)
                .frame(width: size, height: size)
                .background(shape.fill(fill))
                .overlay(
                    shape.strokeBorder(
                        LinearGradient(colors: [.white.opacity(0.45), .white.opacity(0.04)], startPoint: .top, endPoint: .bottom),
                        lineWidth: 1.2
                    )
                )
                .background(shape.fill(lip).offset(y: 5))
                .shadow(color: glow.opacity(0.55), radius: 14, y: 6)
        }
        .buttonStyle(.pressable)
        .opacity(look == .dim || look == .dimDone ? 0.35 : 1)
        .keyframeAnimator(initialValue: 1.0, trigger: look == .done) { view, scale in
            view.scaleEffect(scale)
        } keyframes: { _ in
            SpringKeyframe(1.16, duration: 0.12)
            SpringKeyframe(1.0, duration: 0.35, spring: .bouncy)
        }
    }

    private var fill: AnyShapeStyle {
        switch look {
        case .todo, .dim: AnyShapeStyle(Theme.glassGradient)
        case .done, .dimDone: AnyShapeStyle(Theme.greenGradient)
        case .wrong: AnyShapeStyle(Theme.fireGradient)
        }
    }

    private var lip: Color {
        switch look {
        case .todo, .dim: .black.opacity(0.3)
        case .done, .dimDone: Color(hex: 0x0E7A52)
        case .wrong: Color(hex: 0x9E2A14)
        }
    }

    private var glow: Color {
        switch look {
        case .todo, .dim, .dimDone: .clear
        case .done: Theme.green
        case .wrong: Theme.fire
        }
    }
}

#Preview {
    TapNumbersGame(onComplete: {})
        .screen()
}
