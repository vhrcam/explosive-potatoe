import SwiftUI

private struct Crate: Identifiable {
    let id: Int
    let color: Int
    let home: CGPoint
    let tilt: Double
    var sorted = false
}

struct SortCratesGame: View {
    let onComplete: () -> Void

    @State private var crates: [Crate] = [
        CGPoint(x: 48, y: 80), CGPoint(x: 126, y: 66), CGPoint(x: 204, y: 86), CGPoint(x: 281, y: 70)
    ].enumerated().map { i, home in
        Crate(id: i, color: Int.random(in: 0..<3), home: home, tilt: [-8, 6, -4, 9][i])
    }
    @State private var dragging: Int?
    @State private var dragOffset = CGSize.zero
    @State private var wrongBin: Int?
    @State private var wrongColor = 0

    private let binX: [CGFloat] = [50, 164, 279]
    private let binTop: CGFloat = 290
    private var sortedCount: Int { crates.filter(\.sorted).count }
    private var isComplete: Bool { sortedCount == crates.count }

    var body: some View {
        VStack(spacing: 16) {
            header
            ProgressBarView(value: sortedCount, total: crates.count)
            stage
            if isComplete {
                Button("Back to the Potato", action: onComplete)
                    .buttonStyle(.chunky(.green))
            } else {
                FuseWarning()
            }
        }
    }

    @ViewBuilder
    private var header: some View {
        if isComplete {
            MinigameHeader(label: "Minigame complete · +10", labelColor: Theme.green, title: "All sorted!")
        } else if wrongBin != nil {
            let name = Theme.crateNames[wrongColor]
            MinigameHeader(
                label: "Wrong bin · bouncing back",
                labelColor: Theme.red,
                title: "Not that bin!",
                subtitle: "\(name) goes in \(name.lowercased()). The crate flies back to the pile."
            )
        } else {
            MinigameHeader(title: "Sort the Crates", subtitle: "Drag each crate into its color's bin. Wrong bin? It bounces back.")
        }
    }

    private var stage: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 24)
                .fill(Theme.creamDeep)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(Theme.inkMuted, style: StrokeStyle(lineWidth: 2.5, dash: [8, 6]))
                )
                .frame(width: 329, height: 150)

            if isComplete {
                ResultBadge(isCheck: true, size: 110)
                    .position(x: 164, y: 74)
                Sparkle(size: 32).position(x: 56, y: 46)
                Sparkle(size: 36).position(x: 278, y: 38)
                Sparkle(size: 24).position(x: 72, y: 122)
                Sparkle(size: 28).position(x: 284, y: 119)
            }

            ForEach(binX.indices, id: \.self) { bin in
                let inBin = crates.filter { $0.sorted && $0.color == bin }
                ForEach(Array(inBin.enumerated()), id: \.element.id) { slot, crate in
                    CrateView(colorIndex: crate.color, size: 58)
                        .rotationEffect(.degrees(crate.tilt))
                        .position(x: binX[bin] - 8 + CGFloat(slot) * 16, y: binTop + 4)
                }
            }

            ForEach(binX.indices, id: \.self) { bin in
                BinView(colorIndex: bin)
                    .position(x: binX[bin], y: binTop + 56)
            }

            ForEach(binX.indices, id: \.self) { bin in
                if crates.contains(where: { $0.sorted && $0.color == bin }) {
                    ResultBadge(isCheck: true, size: 34)
                        .position(x: binX[bin] + 40, y: binTop - 4)
                }
                if wrongBin == bin {
                    ResultBadge(isCheck: false, size: 60)
                        .position(x: binX[bin] + 10, y: binTop - 6)
                        .transition(.scale)
                }
            }

            ForEach(crates.filter { !$0.sorted }) { crate in
                let isDragging = dragging == crate.id
                CrateView(colorIndex: crate.color, size: 66)
                    .rotationEffect(.degrees(crate.tilt))
                    .scaleEffect(isDragging ? 1.15 : 1)
                    .shadow(color: Theme.ink.opacity(isDragging ? 0.25 : 0), radius: 0, x: 8, y: 10)
                    .offset(isDragging ? dragOffset : .zero)
                    .gesture(
                        DragGesture(coordinateSpace: .global)
                            .onChanged { value in
                                dragging = crate.id
                                dragOffset = value.translation
                            }
                            .onEnded { value in drop(crate, translation: value.translation) }
                    )
                    .position(crate.home)
                    .zIndex(isDragging ? 1 : 0)
            }
        }
        .frame(width: 329, height: 410, alignment: .topLeading)
        .allowsHitTesting(!isComplete)
    }

    private func drop(_ crate: Crate, translation: CGSize) {
        let point = CGPoint(x: crate.home.x + translation.width, y: crate.home.y + translation.height)
        let bin = binX.indices.first { i in
            CGRect(x: binX[i] - 55, y: binTop - 50, width: 110, height: 170).contains(point)
        }

        if bin == crate.color {
            dragging = nil
            dragOffset = .zero
            withAnimation(.spring(duration: 0.3)) {
                crates[crate.id].sorted = true
            }
        } else {
            if let bin {
                wrongColor = crate.color
                withAnimation(.spring(duration: 0.3)) { wrongBin = bin }
                Task {
                    try? await Task.sleep(for: .seconds(1.2))
                    withAnimation { wrongBin = nil }
                }
            }
            withAnimation(.spring(duration: 0.5, bounce: 0.4)) {
                dragOffset = .zero
            } completion: {
                dragging = nil
            }
        }
    }
}

#Preview {
    SortCratesGame(onComplete: {})
        .screen()
}
