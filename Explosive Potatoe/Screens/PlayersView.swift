import SwiftUI

struct PlayersView: View {
    let game: GameModel
    @State private var appeared = false

    private var missing: Int { max(game.minPlayers - game.players.count, 0) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                CircleIconButton(systemName: "chevron.left") { game.phase = .home }
                Spacer()
                PlayerCountChip(count: game.players.count, minimum: game.minPlayers, maximum: game.maxPlayers)
            }
            .staggerIn(appeared, 0)

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Who's playing?")
                        .font(.lilita(40))
                        .foregroundStyle(Theme.text)
                    Text("\(game.minPlayers) to \(game.maxPlayers) players. A random one sets the first punishment.")
                        .font(.fredoka(16))
                        .foregroundStyle(Theme.textDim)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                PotatoSlot(width: 58)
            }
            .staggerIn(appeared, 1)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(game.players) { player in
                        PlayerRow(player: player) {
                            withAnimation(.spring(duration: 0.4, bounce: 0.3)) { game.removePlayer(player) }
                        }
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.85).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    }
                    if !game.isFull {
                        addButton
                    }
                }
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
            .staggerIn(appeared, 2)

            SectionLabel(text: "Game mode", color: Theme.textFaint, alignment: .leading)
                .staggerIn(appeared, 3)
            HStack(spacing: 10) {
                ForEach(GameType.allCases) { type in
                    ModeCard(type: type, isSelected: game.gameType == type) {
                        withAnimation(.spring(duration: 0.35, bounce: 0.4)) { game.gameType = type }
                    }
                }
            }
            .staggerIn(appeared, 4)
            Text(game.gameType.blurb)
                .font(.fredoka(15))
                .foregroundStyle(Theme.textDim)
                .frame(maxWidth: .infinity)
                .id(game.gameType)
                .transition(.opacity)
                .staggerIn(appeared, 5)

            Group {
                if missing > 0 {
                    Button { game.phase = .addPlayers } label: {
                        Label("Add \(missing) More", systemImage: "person.badge.plus")
                    }
                    .buttonStyle(.chunky(.secondary))
                } else {
                    Button { game.startGame() } label: {
                        Label("Let's Go", systemImage: "flame.fill")
                    }
                    .buttonStyle(.chunky())
                }
            }
            .padding(.top, 4)
            .staggerIn(appeared, 6)
        }
        .screen()
        .onAppear { appeared = true }
    }

    private var addButton: some View {
        Button {
            SFX.play(.tap)
            Haptics.tap()
            game.phase = .addPlayers
        } label: {
            Label("Add players", systemImage: "plus")
                .font(.fredoka(18, .semibold))
                .foregroundStyle(Theme.textDim)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .contentShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Theme.stroke, style: StrokeStyle(lineWidth: 1.5, dash: [7, 6]))
                )
        }
        .buttonStyle(.pressable)
    }
}

struct PlayerRow: View {
    let player: Player
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Avatar(name: player.name, colorIndex: player.colorIndex, size: 40)
            Text(player.name)
                .font(.fredoka(19, .semibold))
                .foregroundStyle(Theme.text)
                .lineLimit(1)
            Spacer()
            Button {
                SFX.play(.tap)
                Haptics.tap()
                onRemove()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.textDim)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Theme.surface))
            }
            .buttonStyle(.pressable)
        }
        .glassCard(cornerRadius: 20, padding: 12)
    }
}

struct PlayerCountChip: View {
    let count: Int
    let minimum: Int
    let maximum: Int

    var body: some View {
        let ready = count >= minimum
        HStack(spacing: 6) {
            Image(systemName: ready ? "checkmark.circle.fill" : "person.2.fill")
            Text("\(count) / \(maximum)")
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(count)))
        }
        .font(.fredoka(14, .bold))
        .foregroundStyle(ready ? Theme.green : Theme.textDim)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(Capsule().fill(ready ? Theme.green.opacity(0.15) : Theme.surface))
        .overlay(Capsule().strokeBorder(ready ? Theme.green.opacity(0.5) : Theme.stroke, lineWidth: 1))
        .animation(.spring(duration: 0.4, bounce: 0.4), value: count)
    }
}

private struct ModeCard: View {
    let type: GameType
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button {
            SFX.play(.tap)
            Haptics.tap()
            onSelect()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: type.symbol)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(isSelected ? AnyShapeStyle(Theme.goldGradient) : AnyShapeStyle(Theme.textDim))
                    .symbolEffect(.bounce, value: isSelected)
                    .frame(height: 28)
                Text(type.title)
                    .font(.fredoka(15, .bold))
                    .foregroundStyle(isSelected ? Theme.text : Theme.textDim)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(type.rounds == 1 ? "1 round" : "\(type.rounds) rounds")
                    .font(.fredoka(12, .semibold))
                    .foregroundStyle(Theme.textFaint)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 6)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(isSelected ? Theme.surfaceStrong : Theme.surface))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(isSelected ? AnyShapeStyle(Theme.fireGradient) : AnyShapeStyle(Theme.stroke), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: Theme.ink.opacity(isSelected ? 0.18 : 0), radius: 6, x: 0, y: 3)
            .scaleEffect(isSelected ? 1 : 0.95)
        }
        .buttonStyle(.pressable)
    }
}

#Preview {
    let game = GameModel()
    for name in ["Mia", "Jake", "Sam", "Lex"] { game.addPlayer(name) }
    return PlayersView(game: game)
}
