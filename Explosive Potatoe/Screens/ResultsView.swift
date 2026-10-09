import SwiftUI

struct ResultsView: View {
    let game: GameModel

    var body: some View {
        let ranked = game.ranked
        VStack(spacing: 16) {
            SectionLabel(text: "After \(game.gameType.rounds) rounds")
            Text("Final Results")
                .font(.lilita(42))
                .foregroundStyle(Theme.ink)

            if let winner = ranked.first {
                VStack(spacing: 4) {
                    CrownView()
                    Text(winner.name)
                        .font(.lilita(46))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Text("\(winner.points) pts  ·  \(explodedText(winner))")
                        .font(.fredoka(17, .semibold))
                        .foregroundStyle(Theme.ink)
                }
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 26).fill(Theme.yellow))
                .overlay(RoundedRectangle(cornerRadius: 26).strokeBorder(Theme.ink, lineWidth: 3))
                .background(RoundedRectangle(cornerRadius: 26).fill(Theme.ink).offset(y: 6))
            }

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Array(ranked.dropFirst().enumerated()), id: \.element.id) { index, player in
                        RankRow(rank: index + 2, player: player)
                    }
                }
                .padding(.top, 6)
                .padding(.bottom, 6)
            }
            .scrollIndicators(.hidden)

            Button("Play Again") { game.startGame() }
                .buttonStyle(.chunky())
            Button("New Players") { game.phase = .players }
                .buttonStyle(.chunky(.secondary))
                .padding(.top, 4)
        }
        .screen()
    }

    private func explodedText(_ player: Player) -> String {
        player.losses == 0 ? "never exploded" : "exploded ×\(player.losses)"
    }
}

private struct RankRow: View {
    let rank: Int
    let player: Player

    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.lilita(24))
                .foregroundStyle(Theme.inkMuted)
                .frame(width: 22)
            Avatar(name: player.name, colorIndex: player.colorIndex)
            Text(player.name)
                .font(.fredoka(19, .semibold))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
            Spacer()
            if player.losses > 0 {
                HStack(spacing: 3) {
                    ExplosionIcon()
                    Text("×\(player.losses)")
                        .font(.fredoka(14, .bold))
                        .foregroundStyle(Theme.inkMuted)
                }
            }
            Text("\(player.points) pts")
                .font(.fredoka(17, .bold))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 18).fill(.white))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.ink, lineWidth: 2.5))
        .background(RoundedRectangle(cornerRadius: 18).fill(Theme.rowShadow).offset(y: 4))
    }
}
