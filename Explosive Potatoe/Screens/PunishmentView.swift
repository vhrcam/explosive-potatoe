import SwiftUI

struct PunishmentView: View {
    @Bindable var game: GameModel
    @FocusState private var focused: Bool

    private var isEmpty: Bool {
        game.punishment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 16) {
            Pill(text: "ROUND \(game.round) OF \(game.gameType.rounds)")

            Text("\(game.name(game.holder)), set the punishment")
                .font(.lilita(38))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.6)

            Text("Whoever's holding the potato when it blows has to do it.")
                .font(.fredoka(16))
                .foregroundStyle(Theme.inkMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: "Punishment", alignment: .leading)
                TextField("Loser has to…", text: $game.punishment, axis: .vertical)
                    .font(.fredoka(22, .semibold))
                    .foregroundStyle(Theme.ink)
                    .tint(Theme.red)
                    .lineLimit(2...3)
                    .focused($focused)
                    .onChange(of: game.punishment) {
                        if game.punishment.count > game.maxPunishmentLength {
                            game.punishment = String(game.punishment.prefix(game.maxPunishmentLength))
                        }
                    }
                Text("\(game.punishment.count) / \(game.maxPunishmentLength)")
                    .font(.fredoka(13, .bold))
                    .foregroundStyle(Theme.inkMuted)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 22)
            .background(RoundedRectangle(cornerRadius: 22).fill(.white))
            .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Theme.ink, lineWidth: 3))
            .background(RoundedRectangle(cornerRadius: 22).fill(Theme.rowShadow).offset(y: 6))
            .onTapGesture { focused = true }

            SectionLabel(text: "Quick picks", alignment: .leading)
                .padding(.top, 4)
            FlowLayout(spacing: 8) {
                ForEach(game.quickPicks, id: \.self) { pick in
                    Button {
                        game.punishment = pick
                        focused = false
                    } label: {
                        Pill(text: pick, fill: Theme.creamDeep)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                PotatoImage(mood: .nervous, width: 54)
                Text("Fuse length is a secret…")
                    .font(.fredoka(15))
                    .foregroundStyle(Theme.inkMuted)
            }

            Button("Light the Fuse") {
                focused = false
                game.startRound()
            }
            .buttonStyle(.chunky())
            .disabled(isEmpty)
        }
        .screen()
        .onTapGesture { focused = false }
    }
}

#Preview {
    let game = GameModel()
    for name in ["Mia", "Sam", "Lex"] { game.addPlayer(name) }
    game.holder = 1
    return PunishmentView(game: game)
}
