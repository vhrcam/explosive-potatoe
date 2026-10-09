import SwiftUI

struct HoldReleaseGame: View {
    let onComplete: () -> Void

    @State private var holdStart: Date?
    @State private var targetStart = Double.random(in: 0.55...0.8)
    @State private var missText: String?
    @State private var isComplete = false

    private let fillTime = 1.6
    private let targetSize = 0.12

    var body: some View {
        VStack(spacing: 16) {
            header

            TimelineView(.animation(paused: holdStart == nil)) { context in
                let fill = progress(at: context.date)
                ZStack {
                    Circle()
                        .stroke(Theme.creamDeep, lineWidth: 30)
                    Circle()
                        .trim(from: targetStart, to: targetStart + targetSize)
                        .stroke(Theme.green, lineWidth: 30)
                    Circle()
                        .trim(from: 0, to: fill)
                        .stroke(Theme.red, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    Circle()
                        .stroke(Theme.ink, lineWidth: 3)
                        .padding(-15)
                    Circle()
                        .stroke(Theme.ink, lineWidth: 3)
                        .padding(15)
                }
                .rotationEffect(.degrees(-90))
                .frame(width: 220, height: 220)
            }
            .overlay {
                if isComplete {
                    ResultBadge(isCheck: true, size: 110)
                        .transition(.scale)
                }
            }
            .padding(.vertical, 24)

            if isComplete {
                CompleteFooter(onDone: onComplete)
            } else {
                Text("HOLD")
                    .font(.lilita(34))
                    .foregroundStyle(.white)
                    .frame(width: 140, height: 140)
                    .background(Circle().fill(holdStart == nil ? Theme.red : Theme.redShadow))
                    .overlay(Circle().strokeBorder(Theme.ink, lineWidth: 4))
                    .background(Circle().fill(Theme.redShadow).offset(y: holdStart == nil ? 7 : 2))
                    .offset(y: holdStart == nil ? 0 : 5)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if holdStart == nil { holdStart = .now }
                            }
                            .onEnded { _ in release() }
                    )
                Spacer(minLength: 0)
                FuseWarning()
            }
        }
    }

    @ViewBuilder
    private var header: some View {
        if isComplete {
            MinigameHeader(label: "Minigame complete · +10", labelColor: Theme.green, title: "Nailed it!")
        } else if let missText {
            MinigameHeader(label: "Missed · new target", labelColor: Theme.red, title: missText, subtitle: "Hold the button, let go in the green.")
        } else {
            MinigameHeader(title: "Hold & Release", subtitle: "Hold the button, let go in the green.")
        }
    }

    private func progress(at date: Date) -> Double {
        guard let holdStart else { return 0 }
        return min(date.timeIntervalSince(holdStart) / fillTime, 1)
    }

    private func release() {
        let fill = progress(at: .now)
        holdStart = nil
        if fill >= targetStart && fill <= targetStart + targetSize {
            withAnimation(.spring(duration: 0.4)) { isComplete = true }
        } else {
            missText = fill < targetStart ? "Too early!" : "Too late!"
            targetStart = Double.random(in: 0.55...0.8)
        }
    }
}

#Preview {
    HoldReleaseGame(onComplete: {})
        .screen()
}
