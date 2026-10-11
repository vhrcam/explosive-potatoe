import SwiftUI

struct ExplosionView: View {
    let game: GameModel
    @State private var flash = 1.0
    @State private var blasted = false
    @State private var stage = 0
    @State private var jolts = 0

    private var loser: Player? {
        game.players.indices.contains(game.holder) ? game.players[game.holder] : nil
    }

    var body: some View {
        VStack(spacing: 14) {
            BoomStamp(blasted: blasted)
                .frame(height: 250)
                .zIndex(1)

            if let loser {
                VStack(spacing: 2) {
                    Text(loser.name)
                        .bigName(Theme.text, size: 54)
                    Text(loser.losses > 1 ? "blew up again · ×\(loser.losses) this game" : "blew up!")
                        .font(.fredoka(18, .semibold))
                        .foregroundStyle(Theme.fire)
                }
                .staggerIn(stage >= 1, 0)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("PUNISHMENT")
                    .font(.fredoka(13, .bold))
                    .tracking(1.4)
                    .foregroundStyle(Theme.fire)
                Text(game.punishment)
                    .font(.hand(34))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(game.punishmentHint)
                    .font(.fredoka(13))
                    .foregroundStyle(Theme.textDim)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .noteCard(rotation: stage >= 2 ? -2 : -14)
            .scaleEffect(stage >= 2 ? 1 : 0.6)
            .offset(y: stage >= 2 ? 0 : 60)
            .opacity(stage >= 2 ? 1 : 0)

            Spacer(minLength: 0)

            Button { game.finishPunishment() } label: {
                Label(
                    game.isLastRound ? "See the Results" : "Done · Next Round",
                    systemImage: game.isLastRound ? "trophy.fill" : "arrow.right"
                )
            }
            .buttonStyle(.chunky(game.isLastRound ? .gold : .primary))
            .staggerIn(stage >= 3, 0)
            .allowsHitTesting(stage >= 3)
        }
        .jolt(jolts)
        .screen(.danger)
        .overlay {
            Color.white
                .opacity(flash)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .task { await detonate() }
    }

    private func detonate() async {
        withAnimation(.easeOut(duration: 0.6)) { flash = 0 }
        blasted = true
        jolts += 1
        SFX.play(.boom)
        Haptics.heavy()
        try? await Task.sleep(for: .milliseconds(140))
        Haptics.heavy()
        for next in 1...3 {
            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(duration: 0.55, bounce: 0.4)) { stage = next }
            if next == 2 {
                SFX.play(.flip)
                Haptics.tap()
            }
        }
    }
}

private struct BoomStamp: View {
    let blasted: Bool

    private var burst: StarburstShape {
        StarburstShape(points: 13, innerRatio: 0.66, irregular: true)
    }

    var body: some View {
        ZStack {
            burst
                .fill(Theme.yellow)
                .overlay(burst.stroke(Theme.ink, style: StrokeStyle(lineWidth: 3.5, lineJoin: .round)))
                .frame(width: 236, height: 236)
                .scaleEffect(x: 1.3, y: 1)
                .shadow(color: Theme.ink.opacity(0.3), radius: 0, x: 4, y: 6)
                .rotationEffect(.degrees(blasted ? 4 : -40))
                .scaleEffect(blasted ? 1 : 0.1)
                .animation(.spring(duration: 0.5, bounce: 0.45), value: blasted)
            Text("BOOM!")
                .font(.lilita(92))
                .foregroundStyle(Theme.fire)
                .shadow(color: Theme.ink, radius: 0, x: 0, y: 5)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .rotationEffect(.degrees(-6))
                .scaleEffect(blasted ? 1 : 2.6)
                .opacity(blasted ? 1 : 0)
                .animation(.spring(duration: 0.5, bounce: 0.5).delay(0.05), value: blasted)
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    let game = GameModel()
    for name in ["Mia", "Sam", "Lex"] { game.addPlayer(name) }
    game.punishment = "Talk in a British accent all next round"
    return ExplosionView(game: game)
}
