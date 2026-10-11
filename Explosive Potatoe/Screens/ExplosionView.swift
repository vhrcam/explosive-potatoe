import SwiftUI

struct ExplosionView: View {
    let game: GameModel
    @State private var flash = 1.0
    @State private var blasted = false
    @State private var stage = 0
    @State private var jolts = 0
    @State private var chunks = Chunk.burst(30)

    private var loser: Player? {
        game.players.indices.contains(game.holder) ? game.players[game.holder] : nil
    }

    var body: some View {
        VStack(spacing: 14) {
            Text("BOOM!")
                .font(.lilita(110))
                .foregroundStyle(.white)
                .shadow(color: Theme.fire, radius: 0, x: 0, y: 6)
                .shadow(color: Theme.orange.opacity(0.8), radius: 30)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .rotationEffect(.degrees(-6))
                .scaleEffect(blasted ? 1 : 2.8)
                .opacity(blasted ? 1 : 0)
                .animation(.spring(duration: 0.5, bounce: 0.5), value: blasted)
                .zIndex(1)
                .padding(.top, 8)

            GlowPotato(mood: .boom, width: 180, glow: Theme.fire)
                .scaleEffect(blasted ? 1 : 0.2)
                .animation(.spring(duration: 0.7, bounce: 0.55).delay(0.08), value: blasted)
                .background { BoomBurst(blasted: blasted, chunks: chunks) }
                .frame(height: 220)

            if let loser {
                VStack(spacing: 4) {
                    Text(loser.name)
                        .bigName(Theme.text, size: 54)
                    Text(loser.losses > 1 ? "blew up again · ×\(loser.losses) this game" : "blew up!")
                        .font(.fredoka(18, .semibold))
                        .foregroundStyle(Theme.yellow)
                }
                .staggerIn(stage >= 1, 0)
            }

            VStack(spacing: 10) {
                SectionLabel(text: "Do the punishment", color: Theme.orange)
                Text(game.punishment)
                    .font(.fredoka(24, .semibold))
                    .foregroundStyle(Theme.text)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .glassCard(cornerRadius: 24, padding: 22)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Theme.fireGradient, lineWidth: 2)
            )
            .shadow(color: Theme.fire.opacity(0.45), radius: 22)
            .scaleEffect(stage >= 2 ? 1 : 0.6)
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
            withAnimation(.spring(duration: 0.55, bounce: 0.45)) { stage = next }
            if next == 2 {
                SFX.play(.pop)
                Haptics.tap()
            }
        }
    }
}

private struct BoomBurst: View {
    let blasted: Bool
    let chunks: [Chunk]
    @State private var spin = false

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Theme.yellow.opacity(0.8), Theme.fire.opacity(0.35), .clear], center: .center, startRadius: 10, endRadius: 260))
                .frame(width: 520, height: 520)
                .scaleEffect(blasted ? 1 : 0.1)
                .animation(.easeOut(duration: 0.5), value: blasted)
            StarburstShape(points: 14, innerRatio: 0.62, irregular: true)
                .fill(Theme.fire.opacity(0.35))
                .frame(width: 560, height: 560)
                .rotationEffect(.degrees(spin ? 360 : 0))
                .scaleEffect(blasted ? 1 : 0.2)
                .animation(.spring(duration: 0.8, bounce: 0.35), value: blasted)
            StarburstShape(points: 12, innerRatio: 0.6, irregular: true)
                .fill(Theme.orange.opacity(0.4))
                .frame(width: 400, height: 400)
                .rotationEffect(.degrees(spin ? -360 : 0))
                .scaleEffect(blasted ? 1 : 0.2)
                .animation(.spring(duration: 0.7, bounce: 0.4).delay(0.04), value: blasted)
            StarburstShape(points: 10, innerRatio: 0.65, irregular: true)
                .fill(Theme.yellow.opacity(0.45))
                .frame(width: 250, height: 250)
                .scaleEffect(blasted ? 1 : 0.2)
                .animation(.spring(duration: 0.6, bounce: 0.5).delay(0.08), value: blasted)
            Circle()
                .stroke(Color.white, lineWidth: blasted ? 1 : 14)
                .frame(width: 90, height: 90)
                .scaleEffect(blasted ? 8 : 0.4)
                .opacity(blasted ? 0 : 0.9)
                .animation(.easeOut(duration: 0.7), value: blasted)
            ForEach(chunks) { chunk in
                ChunkView(chunk: chunk, blasted: blasted)
            }
            Sparkle(size: 30, fill: Theme.yellow).offset(x: -150, y: -120).scaleEffect(blasted ? 1 : 0)
            Sparkle(size: 18, fill: .white).offset(x: 140, y: -150).scaleEffect(blasted ? 1 : 0)
            Sparkle(size: 24, fill: Theme.yellow).offset(x: 160, y: 60).scaleEffect(blasted ? 1 : 0)
            Sparkle(size: 16, fill: .white).offset(x: -140, y: 90).scaleEffect(blasted ? 1 : 0)
        }
        .animation(.spring(duration: 0.6, bounce: 0.6).delay(0.25), value: blasted)
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.linear(duration: 40).repeatForever(autoreverses: false)) { spin = true }
        }
    }
}

private struct Chunk: Identifiable {
    let id: Int
    let angle: Double
    let distance: Double
    let size: CGFloat
    let spin: Double
    let color: Color
    let isRound: Bool

    static func burst(_ count: Int) -> [Chunk] {
        let colors = [Theme.potato, Theme.potato, Theme.orange, Theme.yellow, Theme.fire]
        return (0..<count).map { i in
            Chunk(
                id: i,
                angle: Double(i) / Double(count) * 2 * .pi + .random(in: -0.2...0.2),
                distance: .random(in: 150...340),
                size: .random(in: 8...22),
                spin: .random(in: -600...600),
                color: colors.randomElement() ?? Theme.potato,
                isRound: .random()
            )
        }
    }
}

private struct ChunkView: View {
    let chunk: Chunk
    let blasted: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: chunk.isRound ? chunk.size / 2 : chunk.size * 0.3)
            .fill(chunk.color)
            .frame(width: chunk.size, height: chunk.size * 0.75)
            .rotationEffect(.degrees(blasted ? chunk.spin : 0))
            .offset(
                x: blasted ? cos(chunk.angle) * chunk.distance : 0,
                y: blasted ? sin(chunk.angle) * chunk.distance + chunk.distance * 0.45 : 0
            )
            .animation(.timingCurve(0.1, 0.8, 0.3, 1, duration: 1.2), value: blasted)
            .opacity(blasted ? 0 : 1)
            .animation(.easeIn(duration: 0.45).delay(0.85), value: blasted)
    }
}

#Preview {
    let game = GameModel()
    for name in ["Mia", "Sam", "Lex"] { game.addPlayer(name) }
    game.punishment = "10 push-ups"
    return ExplosionView(game: game)
}
