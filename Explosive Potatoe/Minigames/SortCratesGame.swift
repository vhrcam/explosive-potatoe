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
        CGPoint(x: 52, y: 78), CGPoint(x: 130, y: 64), CGPoint(x: 206, y: 84), CGPoint(x: 280, y: 68)
    ].enumerated().map { i, home in
        Crate(id: i, color: Int.random(in: 0..<3), home: home, tilt: [-8, 6, -4, 9][i])
    }
    @State private var dragging: Int?
    @State private var dragOffset = CGSize.zero
    @State private var hoverBin: Int?
    @State private var wrongBin: Int?
    @State private var wrongColor = 0
    @State private var misses = 0
    @State private var binMisses = [0, 0, 0]
    @State private var burst: (bin: Int, id: Int)?

    private let binX: [CGFloat] = [56, 165, 274]
    private let binTop: CGFloat = 278
    private var sortedCount: Int { crates.filter(\.sorted).count }
    private var isComplete: Bool { sortedCount == crates.count }

    var body: some View {
        VStack(spacing: 16) {
            header
            ProgressBarView(value: sortedCount, total: crates.count)
            stage
            Spacer(minLength: 0)
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
            MinigameHeader(label: MinigameFX.completeLabel, labelColor: Theme.green, title: "All sorted!")
        } else if wrongBin != nil {
            let name = Theme.crateNames[wrongColor]
            MinigameHeader(
                label: "Wrong bin · bouncing back",
                labelColor: Theme.fire,
                title: "Not that bin!",
                subtitle: "\(name) goes in \(name.lowercased()). Back to the pile."
            )
        } else {
            MinigameHeader(title: "Sort the Crates", subtitle: "Drag each crate into the bin that matches its color.")
        }
    }

    private var stage: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Theme.stroke, style: StrokeStyle(lineWidth: 1.5, dash: [8, 6]))
                )
                .frame(width: 329, height: 150)

            Text("THE PILE")
                .font(.fredoka(11, .bold))
                .tracking(1.6)
                .foregroundStyle(Theme.textFaint)
                .position(x: 164, y: 138)

            if isComplete {
                WinPop(size: 96)
                    .position(x: 164, y: 75)
            }

            ForEach(binX.indices, id: \.self) { bin in
                let inBin = crates.filter { $0.sorted && $0.color == bin }
                ForEach(Array(inBin.enumerated()), id: \.element.id) { slot, crate in
                    CrateView(colorIndex: crate.color, size: 54)
                        .rotationEffect(.degrees(crate.tilt))
                        .position(x: binX[bin] - 10 + CGFloat(slot) * 16, y: binTop + 6 - CGFloat(slot) * 4)
                        .transition(.scale(scale: 1.3).combined(with: .opacity))
                }
            }

            ForEach(binX.indices, id: \.self) { bin in
                BinView(colorIndex: bin, isHot: hoverBin == bin, isFilled: crates.contains { $0.sorted && $0.color == bin })
                    .shake(binMisses[bin], amount: 8)
                    .position(x: binX[bin], y: binTop + 58)
            }

            if let burst {
                Burst(colors: [Theme.crateColors[burst.bin], Theme.yellow, .white], count: 14, distance: 70, pieceSize: 11)
                    .id(burst.id)
                    .position(x: binX[burst.bin], y: binTop + 10)
            }

            ForEach(binX.indices, id: \.self) { bin in
                if wrongBin == bin {
                    MissPop(size: 58)
                        .position(x: binX[bin], y: binTop - 18)
                }
            }

            ForEach(crates.filter { !$0.sorted }) { crate in
                let isDragging = dragging == crate.id
                CrateView(colorIndex: crate.color, size: 64, isLifted: isDragging)
                    .rotationEffect(.degrees(isDragging ? 0 : crate.tilt))
                    .scaleEffect(isDragging ? 1.18 : 1)
                    .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isDragging)
                    .offset(isDragging ? dragOffset : .zero)
                    .gesture(
                        DragGesture(coordinateSpace: .global)
                            .onChanged { value in drag(crate, translation: value.translation) }
                            .onEnded { value in drop(crate, translation: value.translation) }
                    )
                    .position(crate.home)
                    .zIndex(isDragging ? 1 : 0)
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
            }
        }
        .frame(width: 329, height: 400, alignment: .topLeading)
        .allowsHitTesting(!isComplete)
    }

    private func bin(for crate: Crate, translation: CGSize) -> Int? {
        let point = CGPoint(x: crate.home.x + translation.width, y: crate.home.y + translation.height)
        return binX.indices.first { i in
            CGRect(x: binX[i] - 55, y: binTop - 50, width: 110, height: 170).contains(point)
        }
    }

    private func drag(_ crate: Crate, translation: CGSize) {
        if dragging != crate.id {
            SFX.play(.grab)
            Haptics.tap()
        }
        dragging = crate.id
        dragOffset = translation
        let bin = bin(for: crate, translation: translation)
        if bin != hoverBin {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { hoverBin = bin }
            if bin != nil { Haptics.tap() }
        }
    }

    private func drop(_ crate: Crate, translation: CGSize) {
        let bin = bin(for: crate, translation: translation)
        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { hoverBin = nil }

        if bin == crate.color {
            dragging = nil
            dragOffset = .zero
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                crates[crate.id].sorted = true
            }
            burst = (crate.color, (burst?.id ?? 0) + 1)
            if isComplete {
                MinigameFX.win()
            } else {
                MinigameFX.step(Double(sortedCount) / Double(crates.count))
            }
        } else {
            if let bin {
                wrongColor = crate.color
                misses += 1
                binMisses[bin] += 1
                MinigameFX.miss()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { wrongBin = bin }
                let miss = misses
                Task {
                    try? await Task.sleep(for: .seconds(1.2))
                    if misses == miss {
                        withAnimation { wrongBin = nil }
                    }
                }
            }
            withAnimation(.spring(duration: 0.5, bounce: 0.45)) {
                dragOffset = .zero
            } completion: {
                dragging = nil
            }
        }
    }
}

struct CrateView: View {
    let colorIndex: Int
    var size: CGFloat = 64
    var isLifted = false

    var body: some View {
        let color = Theme.crateColors[colorIndex]
        let dark = Theme.crateDark[colorIndex]
        let shape = RoundedRectangle(cornerRadius: size * 0.16, style: .continuous)
        let inset = size * 0.15
        ZStack {
            shape.fill(LinearGradient(colors: [color.mix(with: .white, by: 0.25), color], startPoint: .top, endPoint: .bottom))
            RoundedRectangle(cornerRadius: size * 0.06)
                .stroke(dark.opacity(0.75), lineWidth: size * 0.06)
                .padding(inset)
            CrossShape()
                .stroke(dark.opacity(0.75), style: StrokeStyle(lineWidth: size * 0.06, lineCap: .round))
                .padding(inset)
            shape.strokeBorder(LinearGradient(colors: [.white.opacity(0.6), .white.opacity(0.05)], startPoint: .top, endPoint: .bottom), lineWidth: 1.5)
        }
        .frame(width: size, height: size)
        .background(shape.fill(dark).offset(y: size * 0.08))
        .shadow(color: color.opacity(isLifted ? 0.8 : 0.35), radius: isLifted ? 18 : 8, y: isLifted ? 14 : 4)
    }
}

private struct BinBodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.1, y: rect.maxY - 8))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.1, y: rect.maxY - 8),
            control: CGPoint(x: rect.midX, y: rect.maxY + 6)
        )
        path.closeSubpath()
        return path
    }
}

struct BinView: View {
    let colorIndex: Int
    var isHot = false
    var isFilled = false

    var body: some View {
        let color = Theme.crateColors[colorIndex]
        let dark = Theme.crateDark[colorIndex]
        ZStack(alignment: .top) {
            ZStack {
                BinBodyShape()
                    .fill(LinearGradient(colors: [color.opacity(0.55), color.opacity(0.18)], startPoint: .top, endPoint: .bottom))
                BinBodyShape()
                    .fill(RadialGradient(colors: [color.opacity(isHot ? 0.7 : 0.25), .clear], center: .top, startRadius: 0, endRadius: 80))
                VStack(spacing: 6) {
                    if isFilled {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundStyle(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                    Text(Theme.crateNames[colorIndex].uppercased())
                        .font(.fredoka(13, .bold))
                        .tracking(1.2)
                        .foregroundStyle(.white.opacity(0.9))
                }
                .offset(y: 10)
                BinBodyShape()
                    .stroke(color.opacity(0.9), style: StrokeStyle(lineWidth: 2, lineJoin: .round))
            }
            .frame(width: 88, height: 100)
            .offset(y: 12)

            Capsule()
                .fill(LinearGradient(colors: [color.mix(with: .white, by: 0.3), dark], startPoint: .top, endPoint: .bottom))
                .overlay(Capsule().strokeBorder(.white.opacity(0.35), lineWidth: 1))
                .frame(width: 102, height: 16)
        }
        .frame(width: 102, height: 112, alignment: .top)
        .shadow(color: color.opacity(isHot ? 0.9 : 0.3), radius: isHot ? 24 : 10)
        .scaleEffect(isHot ? 1.08 : 1, anchor: .bottom)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isFilled)
    }
}

#Preview {
    SortCratesGame(onComplete: {})
        .screen()
}
