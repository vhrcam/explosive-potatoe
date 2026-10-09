import SwiftUI

struct AddPlayersView: View {
    let game: GameModel
    @State private var newName = ""
    @FocusState private var nameFocused: Bool

    private var canAdd: Bool {
        !newName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button { game.phase = .players } label: { BackButtonLabel() }
                Spacer()
                countChip
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Add players")
                        .font(.lilita(38))
                        .foregroundStyle(Theme.ink)
                    Text("Type a name, tap Add.")
                        .font(.fredoka(16))
                        .foregroundStyle(Theme.inkMuted)
                }
                Spacer()
                PotatoImage(mood: .happy, width: 64)
                    .rotationEffect(.degrees(8))
            }

            HStack(spacing: 10) {
                TextField("Name", text: $newName)
                    .font(.fredoka(24, .semibold))
                    .foregroundStyle(Theme.ink)
                    .tint(Theme.red)
                    .focused($nameFocused)
                    .submitLabel(.done)
                    .onSubmit(add)
                Button("Add", action: add)
                    .font(.fredoka(17, .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Theme.red))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.ink, lineWidth: 2.5))
                    .background(RoundedRectangle(cornerRadius: 14).fill(Theme.redShadow).offset(y: 4))
                    .opacity(canAdd ? 1 : 0.5)
                    .disabled(!canAdd)
            }
            .padding(.leading, 18)
            .padding(.trailing, 10)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 20).fill(.white))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.red, lineWidth: 3))
            .background(RoundedRectangle(cornerRadius: 20).fill(Theme.ink).offset(y: 5))

            if !game.players.isEmpty {
                SectionLabel(text: "In the game", alignment: .leading)
                ScrollView {
                    FlowLayout(spacing: 8) {
                        ForEach(game.players) { player in
                            PlayerChip(player: player) { game.removePlayer(player) }
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .frame(maxHeight: 160)
                .fixedSize(horizontal: false, vertical: true)
            }

            Text("Names show up big when it's your turn.")
                .font(.fredoka(14))
                .foregroundStyle(Theme.inkMuted)

            Spacer(minLength: 0)
        }
        .screen(blob: Theme.creamDeep.opacity(0.6))
        .onAppear { nameFocused = true }
    }

    private var countChip: some View {
        let count = game.players.count
        let ready = game.hasEnoughPlayers
        return Text(ready ? "\(count) players ✓" : "\(count) of \(game.minPlayers) players")
            .font(.fredoka(14, .bold))
            .foregroundStyle(ready ? .white : Theme.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Capsule().fill(ready ? Theme.green : Theme.creamDeep))
            .overlay(Capsule().strokeBorder(Theme.ink, lineWidth: 2.5))
    }

    private func add() {
        guard canAdd else { return }
        game.addPlayer(newName)
        newName = ""
        nameFocused = true
    }
}

private struct PlayerChip: View {
    let player: Player
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Avatar(name: player.name, colorIndex: player.colorIndex, size: 26)
            Text(player.name)
                .font(.fredoka(16, .semibold))
                .foregroundStyle(Theme.ink)
            Button(action: onRemove) {
                Text("✕")
                    .font(.fredoka(13, .bold))
                    .foregroundStyle(Theme.inkMuted)
            }
        }
        .padding(.leading, 8)
        .padding(.trailing, 14)
        .padding(.vertical, 7)
        .background(Capsule().fill(.white))
        .overlay(Capsule().strokeBorder(Theme.ink, lineWidth: 2.5))
    }
}

#Preview {
    let game = GameModel()
    for name in ["Mia", "Sam", "Lex"] { game.addPlayer(name) }
    return AddPlayersView(game: game)
}
