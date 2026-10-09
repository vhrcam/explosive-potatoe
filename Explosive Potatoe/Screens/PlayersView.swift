import SwiftUI

struct PlayersView: View {
    let game: GameModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button { game.phase = .home } label: { BackButtonLabel() }
                Spacer()
            }

            Text("Who's playing?")
                .font(.lilita(40))
                .foregroundStyle(Theme.ink)
            Text("Add at least \(game.minPlayers) players. A random one sets the first punishment.")
                .font(.fredoka(16))
                .foregroundStyle(Theme.inkMuted)
                .fixedSize(horizontal: false, vertical: true)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(game.players) { player in
                        PlayerRow(player: player) { game.removePlayer(player) }
                    }
                    Button { game.phase = .addPlayers } label: {
                        Text("+  Add player")
                            .font(.fredoka(18, .semibold))
                            .foregroundStyle(Theme.inkMuted)
                            .frame(maxWidth: .infinity)
                            .frame(height: 63)
                            .contentShape(Rectangle())
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .strokeBorder(Theme.inkMuted, style: StrokeStyle(lineWidth: 2.5, dash: [7, 5]))
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 6)
            }
            .scrollIndicators(.hidden)

            SectionLabel(text: "Game type", alignment: .leading)
            HStack(spacing: 10) {
                Pill(text: "✓ \(GameType.threeRounds.rawValue)", fill: Theme.yellow)
                Pill(text: "Quick Blast · soon", fill: .clear, textColor: Theme.inkMuted, border: Theme.inkMuted, dashed: true)
            }

            Button("Next") { game.startGame() }
                .buttonStyle(.chunky())
                .disabled(!game.hasEnoughPlayers)
                .padding(.top, 8)
        }
        .screen()
    }
}

struct PlayerRow: View {
    let player: Player
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Avatar(name: player.name, colorIndex: player.colorIndex)
            Text(player.name)
                .font(.fredoka(20, .semibold))
                .foregroundStyle(Theme.ink)
            Spacer()
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.inkMuted)
                    .frame(width: 36, height: 36)
            }
        }
        .padding(.leading, 14)
        .padding(.trailing, 8)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 20).fill(.white))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.ink, lineWidth: 2.5))
        .background(RoundedRectangle(cornerRadius: 20).fill(Theme.rowShadow).offset(y: 4))
    }
}

struct BackButtonLabel: View {
    var body: some View {
        Image(systemName: "chevron.left")
            .font(.system(size: 16, weight: .heavy))
            .foregroundStyle(Theme.ink)
            .frame(width: 40, height: 40)
            .background(Circle().fill(.white))
            .overlay(Circle().strokeBorder(Theme.ink, lineWidth: 2.5))
    }
}

#Preview {
    let game = GameModel()
    for name in ["Mia", "Jake", "Sam", "Lex"] { game.addPlayer(name) }
    return PlayersView(game: game)
}
