import SwiftUI

struct GameView: View {
    let game: GameModel

    var body: some View {
        Group {
            if game.step == .passing {
                PassingView(game: game)
                    .screen(Theme.slowMo, blob: Theme.slowMoBlob)
            } else {
                VStack(spacing: 16) {
                    GameHUD(game: game)
                    content
                        .id(game.turn)
                        .frame(maxHeight: .infinity, alignment: .top)
                }
                .screen()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: game.isSlowMo)
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
            }
        case .holding:
            HoldingView(game: game)
        case .passing:
            EmptyView()
        }
    }
}

private struct HoldingView: View {
    let game: GameModel

    var body: some View {
        VStack(spacing: 16) {
            SectionLabel(text: "Holding the potato")
            Text(game.name(game.holder).uppercased())
                .bigName(Theme.red)

            ZStack {
                Circle()
                    .fill(Theme.yellow.opacity(0.35))
                    .frame(width: 300, height: 300)
                    .offset(y: -5)
                Ellipse()
                    .fill(Theme.ink.opacity(0.12))
                    .frame(width: 150, height: 22)
                    .offset(y: 158)
                HStack {
                    ShakeLines()
                    Spacer()
                    ShakeLines(flipped: true)
                }
                .offset(y: 20)
                WobblingPotato(game: game, width: 230, amount: 6)
            }
            .frame(height: 340)

            Text("Pass it before it blows!")
                .font(.fredoka(18))
                .foregroundStyle(Theme.inkMuted)

            Spacer(minLength: 0)

            Button("Pass to \(game.name(game.target))  →", action: game.pass)
                .buttonStyle(.chunky())
            Text("+\(game.passPoints) pts for every pass")
                .font(.fredoka(13))
                .foregroundStyle(Theme.inkMuted)
        }
    }
}

private struct WobblingPotato: View {
    let game: GameModel
    var mood = PotatoImage.Mood.nervous
    let width: CGFloat
    var amount: Double = 6

    var body: some View {
        PotatoImage(mood: mood, width: width)
            .rotationEffect(.degrees(sin(game.potatoTime * 18) * amount))
    }
}

private struct PassingView: View {
    let game: GameModel

    var body: some View {
        VStack(spacing: 16) {
            Pill(text: "SLOW-MO  ·  0.5×", fill: Theme.blue, textColor: .white)

            SectionLabel(text: "\(game.name(game.passer)) passed to")
            Text(game.name(game.target).uppercased())
                .bigName(Theme.blue)

            ZStack(alignment: .topLeading) {
                SpeedLines()
                    .offset(x: 10, y: 190)
                PotatoImage(mood: .nervous, width: 190)
                    .rotationEffect(.degrees(-14))
                    .opacity(0.18)
                    .offset(x: 0, y: 110)
                PotatoImage(mood: .nervous, width: 210)
                    .rotationEffect(.degrees(-6))
                    .opacity(0.35)
                    .offset(x: 50, y: 60)
                WobblingPotato(game: game, width: 230, amount: 4)
                    .rotationEffect(.degrees(10))
                    .offset(x: 110, y: 0)
            }
            .frame(width: 329, height: 320, alignment: .topLeading)

            AutoPassBar(game: game)

            Text(game.passPending
                 ? "If it blows mid-air, \(game.name(game.passer)) takes the hit."
                 : "Too slow! It's yours now, \(game.name(game.target)). −\(game.lateGivePenalty)")
                .font(.fredoka(16))
                .foregroundStyle(game.passPending ? Theme.inkMuted : Theme.red)
                .multilineTextAlignment(.center)

            Spacer(minLength: 0)

            Button("It's \(game.name(game.target))!", action: game.accept)
                .buttonStyle(.chunky(.blue))
        }
    }
}

private struct AutoPassBar: View {
    let game: GameModel

    var body: some View {
        let fraction = game.passElapsed / game.autoGiveTime
        HStack(spacing: 10) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white)
                    Capsule()
                        .fill(Theme.blue)
                        .frame(width: geo.size.width * (1 - fraction))
                    Capsule().strokeBorder(Theme.ink, lineWidth: 2.5)
                }
            }
            .frame(height: 14)

            Text(game.passPending ? String(format: "auto-pass in %.1fs", game.autoGiveTime - game.passElapsed) : "auto-passed!")
                .font(.fredoka(15, .semibold))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
        }
    }
}

private struct SpeedLines: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Capsule().frame(width: 60, height: 5)
            Capsule().frame(width: 70, height: 5).offset(x: 10)
            Capsule().frame(width: 60, height: 5).offset(x: 24)
        }
        .foregroundStyle(Theme.blue)
        .rotationEffect(.degrees(-28))
    }
}

private struct CardStepView: View {
    let game: GameModel
    let minigame: Minigame?

    @State private var showingMinigame = Bool.random()
    @State private var flipScale = 1.0
    @State private var revealed = false
    @State private var spin = 0.0

    var body: some View {
        VStack(spacing: 16) {
            SectionLabel(text: game.cardLabel)
            Text(revealed ? (minigame == nil ? "Safe!" : "Minigame!") : "Minigame or safe?")
                .font(.lilita(38))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            ZStack {
                cardBack
                    .rotationEffect(.degrees(8))
                    .offset(x: 26, y: -12)
                cardFront
                    .scaleEffect(x: flipScale, y: 1)
                    .rotationEffect(.degrees(-6))
                    .offset(x: -14, y: 8)
                Circle()
                    .trim(from: 0.05, to: 0.4)
                    .stroke(Theme.ink, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(180 + spin))
                    .offset(x: 140, y: -180)
            }
            .frame(height: 420)

            Text("The fuse is still burning…")
                .font(.fredoka(18))
                .foregroundStyle(Theme.inkMuted)

            Spacer(minLength: 0)

            if revealed {
                if minigame == nil {
                    Button("Phew! Keep going", action: game.cardDone)
                        .buttonStyle(.chunky(.green))
                } else {
                    Button("Let's go!", action: game.cardDone)
                        .buttonStyle(.chunky())
                }
            }
        }
        .task { await flip() }
    }

    private var cardFront: some View {
        VStack(spacing: 10) {
            if showingMinigame {
                ZStack {
                    StarburstShape(points: 10, innerRatio: 0.6).fill(Theme.red)
                    StarburstShape(points: 10, innerRatio: 0.6).stroke(Theme.ink, style: StrokeStyle(lineWidth: 3, lineJoin: .round))
                    StarburstShape(points: 10, innerRatio: 0.6).fill(Color(hex: 0xFFF3B0)).padding(26)
                }
                .frame(width: 96, height: 96)
                Text("MINIGAME!")
                    .font(.lilita(44))
                    .foregroundStyle(Theme.ink)
                    .minimumScaleFactor(0.7)
                Text(minigame?.cardHint ?? "Surprise challenge")
                    .font(.fredoka(18, .semibold))
                    .foregroundStyle(Theme.ink)
            } else {
                ResultBadge(isCheck: true, size: 90)
                Text("SAFE!")
                    .font(.lilita(52))
                    .foregroundStyle(.white)
                    .shadow(color: Theme.ink, radius: 0, x: 0, y: 4)
                Text("No minigame. Phew!")
                    .font(.fredoka(18, .semibold))
                    .foregroundStyle(.white)
            }
        }
        .padding(16)
        .frame(width: 273, height: 353)
        .background(RoundedRectangle(cornerRadius: 26).fill(showingMinigame ? Theme.yellow : Theme.green))
        .overlay(RoundedRectangle(cornerRadius: 26).strokeBorder(Theme.ink, lineWidth: 4))
        .background(RoundedRectangle(cornerRadius: 26).fill(Theme.ink).offset(x: 4, y: 8))
    }

    private var cardBack: some View {
        RoundedRectangle(cornerRadius: 26)
            .fill(.white)
            .overlay(RoundedRectangle(cornerRadius: 26).strokeBorder(Theme.ink, lineWidth: 4))
            .background(RoundedRectangle(cornerRadius: 26).fill(Theme.ink.opacity(0.12)).offset(x: 4, y: 10))
            .frame(width: 260, height: 340)
    }

    private func flip() async {
        let isMinigame = minigame != nil
        let flips = showingMinigame == isMinigame ? 10 : 9
        var delay = 0.04
        withAnimation(.linear(duration: 1.6)) { spin = 360 }
        for _ in 0..<flips {
            withAnimation(.linear(duration: delay)) { flipScale = 0 }
            try? await Task.sleep(for: .seconds(delay))
            showingMinigame.toggle()
            withAnimation(.linear(duration: delay)) { flipScale = 1 }
            try? await Task.sleep(for: .seconds(delay))
            delay *= 1.15
        }
        guard !Task.isCancelled else { return }
        withAnimation(.spring(duration: 0.3)) { revealed = true }
    }
}
