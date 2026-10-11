import SwiftUI

struct GameView: View {
    let game: GameModel
    @State private var confirmQuit = false

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                CircleIconButton(systemName: "xmark") { confirmQuit = true }
                GameHUD(game: game)
            }
            content
                .id(game.turn)
                .frame(maxHeight: .infinity, alignment: .top)
                .transition(.asymmetric(insertion: .scale(scale: 0.92).combined(with: .opacity), removal: .opacity))
        }
        .screen(game.step == .passing ? .slowMo : .night)
        .overlay { DangerVignette(active: game.step == .holding) }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: game.step)
        .confirmationDialog("Quit this game?", isPresented: $confirmQuit, titleVisibility: .visible) {
            Button("Quit to menu", role: .destructive, action: game.quit)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch game.step {
        case .card(let minigame):
            CardStepView(game: game, minigame: minigame)
        case .minigame(let minigame):
            switch minigame {
            case .tapNumbers: TapNumbersGame(onComplete: game.minigameDone)
            case .sortCrates: SortCratesGame(onComplete: game.minigameDone)
            case .fillBucket: FillBucketGame(onComplete: game.minigameDone)
            case .holdRelease: HoldReleaseGame(onComplete: game.minigameDone)
            case .arrowRush: ArrowRushGame(onComplete: game.minigameDone)
            case .cutWire: CutWireGame(onComplete: game.minigameDone)
            }
        case .holding:
            HoldingView(game: game)
        case .passing:
            PassingView(game: game)
        }
    }
}

private struct DangerVignette: View {
    let active: Bool
    @State private var pulse = false

    var body: some View {
        RadialGradient(colors: [.clear, .clear, Theme.fire.opacity(pulse ? 0.34 : 0.1)], center: .center, startRadius: 120, endRadius: 520)
            .ignoresSafeArea()
            .opacity(active ? 1 : 0)
            .allowsHitTesting(false)
            .animation(.easeInOut(duration: 0.4), value: active)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) { pulse = true }
            }
    }
}

private struct HoldingView: View {
    let game: GameModel

    private let throwDistance: CGFloat = -70
    private let throwVelocity: CGFloat = -220

    @State private var thrown = false
    @State private var hintBounce = false

    var body: some View {
        VStack(spacing: 12) {
            SectionLabel(text: "Holding the potato")
            Text(game.name(game.holder).uppercased())
                .bigName(Theme.fire, size: 72)

            ZStack {
                VStack(spacing: -10) {
                    ForEach(0..<3) { i in
                        Image(systemName: "chevron.up")
                            .font(.system(size: 26, weight: .black))
                            .foregroundStyle(Theme.fire.opacity(0.2 + Double(2 - i) * 0.25))
                    }
                }
                .offset(y: hintBounce ? -168 : -154)
                .opacity(thrown ? 0 : 1)

                HStack {
                    ShakeLines()
                    Spacer()
                    ShakeLines(flipped: true)
                }
                .padding(.horizontal, 30)
                .offset(y: 30)

                Ellipse()
                    .fill(Theme.ink.opacity(0.14))
                    .frame(width: 130, height: 18)
                    .blur(radius: 4)
                    .offset(y: 140)

                PotatoSlot(width: 210)
            }
            .frame(height: 330)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) { hintBounce = true }
            }

            HStack(spacing: 10) {
                Text("Flick it to")
                    .font(.fredoka(17))
                    .foregroundStyle(Theme.textDim)
                Avatar(name: game.name(game.target), colorIndex: game.players[game.target].colorIndex, size: 30)
                Text(game.name(game.target))
                    .font(.fredoka(19, .bold))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Capsule().fill(Theme.card))
            .overlay(Capsule().strokeBorder(Theme.stroke, lineWidth: 1))
            .shadow(color: Theme.shadow, radius: 4, y: 2)

            Spacer(minLength: 0)

            SwipeUpHint()
                .opacity(thrown ? 0 : 1)
            Text("+\(game.passPoints) pts for every pass")
                .font(.fredoka(13))
                .foregroundStyle(Theme.textFaint)
        }
        .contentShape(Rectangle())
        .gesture(flick)
    }

    private var flick: some Gesture {
        DragGesture()
            .onChanged { value in
                guard !thrown else { return }
                game.potatoDrag = CGSize(width: value.translation.width * 0.5, height: min(value.translation.height, 40))
            }
            .onEnded { value in
                guard !thrown else { return }
                let velocity = value.predictedEndTranslation.height - value.translation.height
                if value.translation.height < throwDistance || velocity < throwVelocity {
                    throwPotato()
                } else {
                    game.potatoDrag = .zero
                }
            }
    }

    private func throwPotato() {
        guard !thrown else { return }
        thrown = true
        game.potatoDrag = CGSize(width: game.potatoDrag.width, height: -900)
        Task {
            try? await Task.sleep(for: .seconds(0.18))
            game.pass()
        }
    }
}

private struct SwipeUpHint: View {
    @State private var swipe = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Capsule()
                    .fill(Theme.fire.opacity(0.12))
                    .frame(width: 34, height: 58)
                Image(systemName: "hand.point.up.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Theme.fire)
                    .offset(y: swipe ? -14 : 12)
                    .opacity(swipe ? 0.2 : 1)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Swipe up to throw")
                    .font(.lilita(24))
                    .foregroundStyle(Theme.text)
                Text("Anywhere on the screen works")
                    .font(.fredoka(14))
                    .foregroundStyle(Theme.textDim)
            }
            Spacer(minLength: 0)
        }
        .glassCard(cornerRadius: 20, padding: 14)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: false)) { swipe = true }
        }
    }
}

private struct PassingView: View {
    let game: GameModel

    private let catchDistance: CGFloat = 70
    private let catchVelocity: CGFloat = 220
    private let forcedPause = 0.9

    var body: some View {
        VStack(spacing: 12) {
            Pill(text: "SLOW-MO  ·  0.5×", fill: Theme.blue, textColor: .white, border: Theme.ink.opacity(0.2))

            SectionLabel(text: "\(game.name(game.passer)) threw it to")
            Text(game.name(game.target).uppercased())
                .bigName(Theme.blue, size: 72)

            ZStack {
                SpeedLines()
                    .offset(x: -70, y: -30)
                SpeedLines()
                    .scaleEffect(x: -1)
                    .offset(x: 70, y: -50)
                PotatoSlot(width: 128)
            }
            .frame(height: 190)

            ShakeToCatch(game: game)

            Text(game.passPending
                 ? "If it blows mid-air, \(game.name(game.passer)) takes the hit."
                 : "Too slow! It's yours now, \(game.name(game.target)). −\(game.lateGivePenalty)")
                .font(.fredoka(16, .semibold))
                .foregroundStyle(game.passPending ? Theme.textDim : Theme.fire)
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)
                .animation(.easeInOut, value: game.passPending)

            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
        .gesture(grab)
        .onShake(enabled: game.step == .passing) {
            SFX.play(.rattle)
            game.accept()
        }
        .onAppear {
            game.potatoDrag = .zero
        }
        .onChange(of: game.passPending) {
            guard !game.passPending else { return }
            Task {
                try? await Task.sleep(for: .seconds(forcedPause))
                if game.step == .passing { game.accept() }
            }
        }
    }

    private var grab: some Gesture {
        DragGesture()
            .onEnded { value in
                let velocity = value.predictedEndTranslation.height - value.translation.height
                if value.translation.height > catchDistance || velocity > catchVelocity {
                    game.accept()
                }
            }
    }
}

private struct ShakeToCatch: View {
    let game: GameModel
    @State private var wiggle = false

    private let size: CGFloat = 150

    var body: some View {
        let remaining = max(0, 1 - game.passElapsed / game.autoGiveTime)
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(Theme.ink.opacity(0.1), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: remaining)
                    .stroke(Theme.orange, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Circle()
                    .fill(game.passPending ? Theme.blueGradient : Theme.fireGradient)
                    .padding(16)
                    .overlay(Circle().strokeBorder(Theme.ink.opacity(0.3), lineWidth: 1.5).padding(16))
                    .shadow(color: Theme.shadow, radius: 8, y: 6)
                Image(systemName: game.passPending ? "iphone.gen3.radiowaves.left.and.right" : "tortoise.fill")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(game.passPending ? (wiggle ? 14 : -14) : 0))
            }
            .frame(width: size, height: size)

            Text(game.passPending ? "SHAKE TO CATCH!" : "TOO SLOW")
                .font(.lilita(34))
                .foregroundStyle(game.passPending ? Theme.blue : Theme.fire)
            Text(game.passPending ? String(format: "%.1fs left · or swipe down", game.autoGiveTime - game.passElapsed) : "−\(game.lateGivePenalty) pts")
                .font(.fredoka(15, .bold))
                .foregroundStyle(Theme.textDim)
                .monospacedDigit()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.12).repeatForever(autoreverses: true)) { wiggle = true }
        }
    }
}

private struct SpeedLines: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Capsule().frame(width: 70, height: 4)
            Capsule().frame(width: 90, height: 4).offset(x: 14)
            Capsule().frame(width: 60, height: 4).offset(x: 30)
        }
        .foregroundStyle(Theme.blue.opacity(0.45))
        .rotationEffect(.degrees(70))
    }
}

private struct CardStepView: View {
    let game: GameModel
    let minigame: Minigame?

    @State private var showingMinigame = Bool.random()
    @State private var flipAngle = 0.0
    @State private var revealed = false
    @State private var raysSpin = false
    @State private var chipShown = false
    @State private var advance = 0.0

    private let autoAdvance = 1.2

    var body: some View {
        VStack(spacing: 14) {
            catchChip

            Text(revealed ? (minigame == nil ? "Safe!" : "Minigame!") : "Minigame or safe?")
                .font(.lilita(36))
                .foregroundStyle(Theme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .contentTransition(.opacity)

            ZStack(alignment: .bottomTrailing) {
                cardFace
                    .rotation3DEffect(.degrees(flipAngle), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
                    .scaleEffect(revealed ? 1 : 0.94)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                PotatoSlot(width: 78)
                    .offset(x: -2, y: 6)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 400)
            .background {
                StarburstShape(points: 16, innerRatio: 0.55)
                    .fill(RadialGradient(colors: [(showingMinigame ? Theme.yellow : Theme.green).opacity(0.3), .clear], center: .center, startRadius: 40, endRadius: 230))
                    .frame(width: 460, height: 460)
                    .rotationEffect(.degrees(raysSpin ? 360 : 0))
                    .opacity(revealed ? 1 : 0)
                    .scaleEffect(revealed ? 1 : 0.4)
                    .allowsHitTesting(false)
            }

            Text(revealed ? (minigame == nil ? "Pass it on, quick." : "Beat it for +\(game.minigamePoints). The fuse keeps burning.") : "The fuse is still burning…")
                .font(.fredoka(17))
                .foregroundStyle(Theme.textDim)
                .multilineTextAlignment(.center)

            Spacer(minLength: 0)

            if revealed {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.ink.opacity(0.08))
                        Capsule()
                            .fill(minigame == nil ? Theme.green : Theme.fire)
                            .frame(width: geo.size.width * advance)
                    }
                }
                .frame(width: 160, height: 8)
                .padding(.bottom, 24)
                .transition(.opacity)
            }
        }
        .task { await flip() }
    }

    @ViewBuilder
    private var catchChip: some View {
        let positive = (game.lastCatch?.points ?? 0) >= 0
        HStack(spacing: 8) {
            if let lastCatch = game.lastCatch {
                Image(systemName: positive ? "bolt.fill" : "tortoise.fill")
                Text("\(game.cardLabel)")
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(lastCatch.points >= 0 ? "+\(lastCatch.points)" : "\(lastCatch.points)")
                    .font(.lilita(18))
            } else {
                FuseIcon(size: 16)
                Text(game.cardLabel)
                    .lineLimit(1)
            }
        }
        .font(.fredoka(14, .bold))
        .foregroundStyle(game.lastCatch == nil ? Theme.orange : (positive ? Theme.green : Theme.fire))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Capsule().fill(Theme.card))
        .overlay(Capsule().strokeBorder(Theme.stroke, lineWidth: 1))
        .shadow(color: Theme.shadow, radius: 4, y: 2)
        .scaleEffect(chipShown ? 1 : 0.6)
        .opacity(chipShown ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) { chipShown = true }
        }
    }

    private var cardFace: some View {
        let shape = RoundedRectangle(cornerRadius: 26, style: .continuous)
        return VStack(spacing: 14) {
            if showingMinigame {
                ZStack {
                    StarburstShape(points: 12, innerRatio: 0.7)
                        .fill(.white.opacity(0.22))
                    Image(systemName: revealed ? (minigame?.symbol ?? "questionmark") : "questionmark")
                        .font(.system(size: 40, weight: .black))
                        .foregroundStyle(.white)
                }
                .frame(width: 110, height: 110)
                Text("MINIGAME")
                    .font(.lilita(42))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.7)
                Text(revealed ? (minigame?.cardHint ?? "") : "???")
                    .font(.fredoka(19, .semibold))
                    .foregroundStyle(.white.opacity(0.92))
            } else {
                ZStack {
                    Circle().fill(.white.opacity(0.22))
                    Image(systemName: "checkmark")
                        .font(.system(size: 46, weight: .black))
                        .foregroundStyle(.white)
                }
                .frame(width: 110, height: 110)
                Text("SAFE")
                    .font(.lilita(52))
                    .foregroundStyle(.white)
                Text("No minigame. Phew!")
                    .font(.fredoka(19, .semibold))
                    .foregroundStyle(.white.opacity(0.92))
            }
        }
        .padding(20)
        .frame(width: 270, height: 350)
        .background(
            shape.fill(showingMinigame
                ? LinearGradient(colors: [Color(hex: 0xEF6A3A), Theme.pink, Theme.purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                : LinearGradient(colors: [Color(hex: 0x3DB274), Color(hex: 0x1F7F57)], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .overlay(shape.strokeBorder(.white.opacity(0.6), lineWidth: 6).padding(8))
        .overlay(shape.strokeBorder(Theme.ink.opacity(0.25), lineWidth: 1.5))
        .shadow(color: Theme.shadow, radius: revealed ? 16 : 10, y: revealed ? 10 : 6)
    }

    private func flip() async {
        let isMinigame = minigame != nil
        let flips = showingMinigame == isMinigame ? 10 : 9
        var delay = 0.04
        for _ in 0..<flips {
            withAnimation(.linear(duration: delay)) { flipAngle = 90 }
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            showingMinigame.toggle()
            flipAngle = -90
            SFX.play(.flip)
            withAnimation(.linear(duration: delay)) { flipAngle = 0 }
            try? await Task.sleep(for: .seconds(delay))
            delay *= 1.15
        }
        guard !Task.isCancelled else { return }
        if isMinigame {
            SFX.play(.pop)
            Haptics.heavy()
        } else {
            SFX.play(.success)
            Haptics.success()
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) { revealed = true }
        withAnimation(.linear(duration: 14).repeatForever(autoreverses: false)) { raysSpin = true }
        withAnimation(.linear(duration: autoAdvance)) { advance = 1 }
        try? await Task.sleep(for: .seconds(autoAdvance))
        guard !Task.isCancelled else { return }
        game.cardDone()
    }
}
