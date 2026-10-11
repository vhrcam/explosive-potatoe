import SwiftUI

private enum Arrow: CaseIterable {
    case up, down, left, right

    var symbol: String {
        switch self {
        case .up: "arrowshape.up.fill"
        case .down: "arrowshape.down.fill"
        case .left: "arrowshape.left.fill"
        case .right: "arrowshape.right.fill"
        }
    }

    var color: Color {
        switch self {
        case .up: Theme.green
        case .down: Theme.fire
        case .left: Theme.blue
        case .right: Theme.yellow
        }
    }

    var vector: CGSize {
        switch self {
        case .up: CGSize(width: 0, height: -1)
        case .down: CGSize(width: 0, height: 1)
        case .left: CGSize(width: -1, height: 0)
        case .right: CGSize(width: 1, height: 0)
        }
    }

    init(swipe: CGSize) {
        if abs(swipe.width) > abs(swipe.height) {
            self = swipe.width > 0 ? .right : .left
        } else {
            self = swipe.height > 0 ? .down : .up
        }
    }
}

struct ArrowRushGame: View {
    let onComplete: () -> Void

    @State private var arrow = Arrow.allCases.randomElement() ?? .up
    @State private var arrowID = 0
    @State private var streak = 0
    @State private var misses = 0
    @State private var drag = CGSize.zero
    @State private var wrongFlash = false
    @State private var isComplete = false

    private let goal = 6
    private let minSwipe: CGFloat = 40
    private let flyDistance: CGFloat = 460
    private let followFactor: CGFloat = 0.25
    private let cardSize = CGSize(width: 329, height: 340)

    var body: some View {
        VStack(spacing: 16) {
            header
            StreakPips(value: streak, total: goal)
            stage
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
            MinigameHeader(label: MinigameFX.completeLabel, labelColor: Theme.green, title: "Lightning fingers!")
        } else if misses > 0 && streak == 0 {
            MinigameHeader(label: "Wrong way · streak reset", labelColor: Theme.fire, title: "Other way!", subtitle: "Swipe the way the arrow points, \(goal) in a row.")
        } else {
            MinigameHeader(title: "Arrow Rush", subtitle: "Swipe the way the arrow points, \(goal) in a row.")
        }
    }

    private var stage: some View {
        let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)
        return ZStack {
            shape.fill(Theme.surface)
            shape.fill(RadialGradient(colors: [arrow.color.opacity(isComplete ? 0 : 0.28), .clear], center: .center, startRadius: 0, endRadius: 180))
                .animation(.easeOut(duration: 0.25), value: arrow)
            shape.strokeBorder(wrongFlash ? Theme.fire : Theme.stroke, lineWidth: wrongFlash ? 3 : 1)
                .shadow(color: Theme.fire.opacity(wrongFlash ? 0.8 : 0), radius: 16)

            if isComplete {
                WinPop(size: 120)
            } else {
                Image(systemName: arrow.symbol)
                    .font(.system(size: 150, weight: .black))
                    .foregroundStyle(LinearGradient(colors: [arrow.color.mix(with: .white, by: 0.35), arrow.color], startPoint: .top, endPoint: .bottom))
                    .shadow(color: arrow.color.opacity(0.8), radius: 24)
                    .shadow(color: .black.opacity(0.3), radius: 0, y: 5)
                    .offset(x: drag.width * followFactor, y: drag.height * followFactor)
                    .shake(misses, amount: 16)
                    .id(arrowID)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.2).combined(with: .opacity),
                        removal: .offset(x: arrow.vector.width * flyDistance, y: arrow.vector.height * flyDistance).combined(with: .opacity)
                    ))

                Text("SWIPE ANYWHERE")
                    .font(.fredoka(12, .bold))
                    .tracking(1.6)
                    .foregroundStyle(Theme.textFaint)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 16)
            }
        }
        .frame(width: cardSize.width, height: cardSize.height)
        .clipShape(shape)
        .contentShape(shape)
        .gesture(
            DragGesture(minimumDistance: 12)
                .onChanged { value in drag = value.translation }
                .onEnded { value in swiped(value.translation) }
        )
        .allowsHitTesting(!isComplete)
    }

    private func swiped(_ translation: CGSize) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { drag = .zero }
        guard max(abs(translation.width), abs(translation.height)) >= minSwipe else { return }

        if Arrow(swipe: translation) == arrow {
            streak += 1
            SFX.play(.swish, pitch: Float(0.9 + Double(streak) / Double(goal) * 0.6))
            if streak >= goal {
                MinigameFX.win()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    arrowID += 1
                    isComplete = true
                }
            } else {
                Haptics.tap()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    arrowID += 1
                    arrow = Arrow.allCases.randomElement() ?? .up
                }
            }
        } else {
            streak = 0
            misses += 1
            MinigameFX.miss()
            withAnimation(.easeOut(duration: 0.15)) { wrongFlash = true }
            Task {
                try? await Task.sleep(for: .seconds(0.5))
                withAnimation(.easeOut(duration: 0.3)) { wrongFlash = false }
            }
        }
    }
}

#Preview {
    ArrowRushGame(onComplete: {})
        .screen()
}
