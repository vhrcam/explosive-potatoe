import SwiftUI

struct ResultsView: View {
    let game: GameModel
    @State private var appeared = false
    @State private var risen = 0

    private let podiumHeights: [CGFloat] = [150, 112, 84]
    private let podiumFills = [
        AnyShapeStyle(Theme.goldGradient),
        AnyShapeStyle(LinearGradient(colors: [Color(hex: 0xE9ECF5), Color(hex: 0x8E97AD)], startPoint: .top, endPoint: .bottom)),
        AnyShapeStyle(LinearGradient(colors: [Color(hex: 0xF2A766), Color(hex: 0x9C5126)], startPoint: .top, endPoint: .bottom))
    ]

    private var summary: String {
        let rounds = game.gameType.rounds
        return "\(game.gameType.title) · \(rounds) round\(rounds == 1 ? "" : "s")"
    }

    var body: some View {
        let ranked = game.ranked
        let awards = game.awards
        VStack(spacing: 14) {
            VStack(spacing: 2) {
                SectionLabel(text: summary, color: Theme.textFaint)
                Text("Final Results")
                    .font(.lilita(40))
                    .foregroundStyle(Theme.text)
            }
            .staggerIn(appeared, 0)

            ScrollView {
                VStack(spacing: 18) {
                    podium(Array(ranked.prefix(3)))

                    if ranked.count > 3 {
                        VStack(spacing: 8) {
                            ForEach(Array(ranked.dropFirst(3).enumerated()), id: \.element.id) { index, player in
                                RankRow(rank: index + 4, player: player, revealed: risen >= 3)
                                    .staggerIn(risen >= 3, index)
                            }
                        }
                    }

                    if !awards.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionLabel(text: "Awards", color: Theme.textFaint, alignment: .leading)
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                                ForEach(Array(awards.enumerated()), id: \.element.id) { index, award in
                                    AwardCard(award: award)
                                        .staggerIn(risen >= 3, index + 2)
                                }
                            }
                        }
                        .staggerIn(risen >= 3, 1)
                    }
                }
                .padding(.vertical, 6)
            }
            .scrollIndicators(.hidden)

            VStack(spacing: 12) {
                Button { game.startGame() } label: {
                    Label("Play Again", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.chunky())
                Button { game.phase = .players } label: {
                    Label("New Players", systemImage: "person.2.fill")
                }
                .buttonStyle(.chunky(.secondary))
            }
            .staggerIn(appeared, 1)
        }
        .screen(.victory)
        .overlay { ConfettiBurst(isActive: risen >= 3) }
        .onAppear { appeared = true }
        .task { await reveal() }
    }

    private func podium(_ top: [Player]) -> some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach([1, 0, 2].filter { $0 < top.count }, id: \.self) { place in
                PodiumColumn(
                    place: place + 1,
                    player: top[place],
                    height: podiumHeights[place],
                    fill: podiumFills[place],
                    isUp: risen >= 3 - place
                )
            }
        }
        .frame(height: 320, alignment: .bottom)
    }

    private func reveal() async {
        for step in 1...3 {
            try? await Task.sleep(for: .milliseconds(step == 1 ? 450 : 550))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(duration: 0.6, bounce: 0.4)) { risen = step }
            if step < 3 {
                SFX.play(.pop, pitch: step == 1 ? 0.9 : 1.05)
                Haptics.tap()
            } else {
                SFX.play(.win)
                Haptics.success()
            }
        }
    }
}

private struct PodiumColumn: View {
    let place: Int
    let player: Player
    let height: CGFloat
    let fill: AnyShapeStyle
    let isUp: Bool

    var body: some View {
        VStack(spacing: 6) {
            VStack(spacing: 6) {
                if place == 1 {
                    CrownView()
                        .scaleEffect(0.6)
                        .frame(height: 34)
                        .rotationEffect(.degrees(isUp ? -8 : -40))
                }
                Avatar(name: player.name, colorIndex: player.colorIndex, size: place == 1 ? 64 : 50)
                    .shadow(color: place == 1 ? Theme.yellow.opacity(0.6) : .clear, radius: 16)
                Text(player.name)
                    .font(.fredoka(place == 1 ? 18 : 16, .bold))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                HStack(spacing: 3) {
                    CountUpText(value: isUp ? player.points : 0)
                    Text("pts")
                }
                .font(.fredoka(14, .bold))
                .foregroundStyle(place == 1 ? Theme.yellow : Theme.textDim)
            }
            .opacity(isUp ? 1 : 0)
            .scaleEffect(isUp ? 1 : 0.5, anchor: .bottom)
            .offset(y: isUp ? 0 : 30)

            ZStack(alignment: .top) {
                UnevenRoundedRectangle(topLeadingRadius: 16, topTrailingRadius: 16, style: .continuous)
                    .fill(fill)
                Text("\(place)")
                    .font(.lilita(place == 1 ? 46 : 36))
                    .foregroundStyle(.white.opacity(0.92))
                    .shadow(color: .black.opacity(0.25), radius: 0, x: 0, y: 3)
                    .padding(.top, 10)
            }
            .frame(height: isUp ? height : 8)
            .clipped()
            .shadow(color: place == 1 && isUp ? Theme.yellow.opacity(0.35) : .clear, radius: 20)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct RankRow: View {
    let rank: Int
    let player: Player
    let revealed: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.lilita(22))
                .foregroundStyle(Theme.textFaint)
                .frame(width: 26)
            Avatar(name: player.name, colorIndex: player.colorIndex, size: 36)
            Text(player.name)
                .font(.fredoka(18, .semibold))
                .foregroundStyle(Theme.text)
                .lineLimit(1)
            Spacer()
            if player.losses > 0 {
                HStack(spacing: 3) {
                    ExplosionIcon(size: 15)
                    Text("×\(player.losses)")
                        .font(.fredoka(13, .bold))
                        .foregroundStyle(Theme.textDim)
                }
            }
            HStack(spacing: 3) {
                CountUpText(value: revealed ? player.points : 0)
                Text("pts")
            }
            .font(.fredoka(16, .bold))
            .foregroundStyle(Theme.text)
        }
        .glassCard(cornerRadius: 18, padding: 14)
    }
}

private struct AwardCard: View {
    let award: Award

    var body: some View {
        let color = Theme.avatarColors[award.colorIndex % Theme.avatarColors.count]
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: award.symbol)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Circle().fill(color.gradient))
                .shadow(color: color.opacity(0.5), radius: 10)
            Text(award.title)
                .font(.lilita(19))
                .foregroundStyle(Theme.yellow)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(award.playerName)
                .font(.fredoka(16, .bold))
                .foregroundStyle(Theme.text)
                .lineLimit(1)
            Text(award.detail)
                .font(.fredoka(13))
                .foregroundStyle(Theme.textDim)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 20, padding: 14)
    }
}

private struct ConfettiBurst: View {
    let isActive: Bool
    @State private var pieces = ConfettiPiece.make(70)

    var body: some View {
        GeometryReader { geo in
            ForEach(pieces) { piece in
                RoundedRectangle(cornerRadius: 2)
                    .fill(piece.color)
                    .frame(width: piece.size, height: piece.size * 0.45)
                    .rotation3DEffect(.degrees(isActive ? piece.flips * 360 : 0), axis: (x: 1, y: 0.3, z: 0))
                    .rotationEffect(.degrees(isActive ? piece.spin : 0))
                    .position(
                        x: piece.x * geo.size.width + (isActive ? piece.drift : 0),
                        y: isActive ? geo.size.height + 40 : -40
                    )
                    .animation(.easeIn(duration: piece.duration).delay(piece.delay), value: isActive)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

private struct ConfettiPiece: Identifiable {
    let id: Int
    let x: CGFloat
    let drift: CGFloat
    let size: CGFloat
    let spin: Double
    let flips: Double
    let duration: Double
    let delay: Double
    let color: Color

    static func make(_ count: Int) -> [ConfettiPiece] {
        let colors = [Theme.fire, Theme.orange, Theme.yellow, Theme.green, Theme.blue, Theme.pink, Theme.purple]
        return (0..<count).map { i in
            ConfettiPiece(
                id: i,
                x: .random(in: 0...1),
                drift: .random(in: -60...60),
                size: .random(in: 8...14),
                spin: .random(in: -360...360),
                flips: .random(in: 2...6).rounded(),
                duration: .random(in: 2.2...3.6),
                delay: .random(in: 0...0.8),
                color: colors.randomElement() ?? Theme.yellow
            )
        }
    }
}

#Preview {
    let game = GameModel()
    for name in ["Mia", "Jake", "Sam", "Lex", "Ana"] { game.addPlayer(name) }
    game.players[0].points = 85
    game.players[1].points = 60
    game.players[2].points = 45
    game.players[3].points = 30
    game.players[4].points = 10
    game.phase = .results
    return ResultsView(game: game)
}
