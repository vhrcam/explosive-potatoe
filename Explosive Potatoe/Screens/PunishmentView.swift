import SwiftUI

struct PunishmentView: View {
    @Bindable var game: GameModel
    @FocusState private var focused: Bool
    @State private var appeared = false
    @State private var rolls = 0

    private var isEmpty: Bool {
        game.punishment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var setter: Player? {
        game.players.indices.contains(game.holder) ? game.players[game.holder] : nil
    }

    private var pickRows: [[String]] {
        let picks = game.quickPicks.enumerated()
        return [
            picks.filter { $0.offset.isMultiple(of: 2) }.map(\.element),
            picks.filter { !$0.offset.isMultiple(of: 2) }.map(\.element)
        ]
    }

    var body: some View {
        VStack(spacing: 16) {
            roundPill
                .staggerIn(appeared, 0)

            if let setter {
                VStack(spacing: 4) {
                    if !focused {
                        Avatar(name: setter.name, colorIndex: setter.colorIndex, size: 58)
                            .transition(.scale.combined(with: .opacity))
                    }
                    Text(setter.name)
                        .bigName(Theme.avatarColors[setter.colorIndex % Theme.avatarColors.count], size: 50)
                    Text("set the punishment")
                        .font(.fredoka(18, .semibold))
                        .foregroundStyle(Theme.textDim)
                }
                .staggerIn(appeared, 1)
            }

            editor
                .staggerIn(appeared, 2)

            if !focused {
                quickPicks
                    .staggerIn(appeared, 3)
                    .transition(.opacity)
            }

            Spacer(minLength: 0)

            if !focused {
                HStack(spacing: 10) {
                    PotatoImage(mood: .nervous, width: 40)
                    Text("Fuse length is a secret…")
                        .font(.fredoka(15))
                        .foregroundStyle(Theme.textDim)
                }
                .staggerIn(appeared, 4)
                .transition(.opacity)
            }

            Button {
                focused = false
                SFX.play(.fuseLit)
                Haptics.heavy()
                game.startRound()
            } label: {
                Label("Light the Fuse", systemImage: "flame.fill")
            }
            .buttonStyle(.chunky())
            .disabled(isEmpty)
            .staggerIn(appeared, 5)
        }
        .animation(.spring(duration: 0.35, bounce: 0.2), value: focused)
        .screen()
        .contentShape(Rectangle())
        .onTapGesture { focused = false }
        .onAppear { appeared = true }
    }

    private var roundPill: some View {
        HStack(spacing: 8) {
            Image(systemName: game.gameType.symbol)
            Text("\(game.gameType.title.uppercased()) · ROUND \(game.round)/\(game.gameType.rounds)")
        }
        .font(.fredoka(13, .bold))
        .tracking(1.2)
        .foregroundStyle(Theme.yellow)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Capsule().fill(Theme.surface))
        .overlay(Capsule().strokeBorder(Theme.stroke, lineWidth: 1))
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionLabel(text: "Loser has to…", color: Theme.yellow, alignment: .leading)
                Button {
                    rolls += 1
                    SFX.play(.flip)
                    Haptics.tap()
                    withAnimation(.snappy) { game.randomPunishment() }
                } label: {
                    Image(systemName: "dice.fill")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Theme.text)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(Theme.surfaceStrong))
                        .overlay(Circle().strokeBorder(Theme.stroke, lineWidth: 1))
                        .rotationEffect(.degrees(Double(rolls) * 360))
                        .animation(.spring(duration: 0.6, bounce: 0.35), value: rolls)
                }
                .buttonStyle(.pressable)
            }
            TextField("Punishment", text: $game.punishment, prompt: Text("Type one, or roll the dice").foregroundStyle(Theme.textFaint), axis: .vertical)
                .font(.fredoka(22, .semibold))
                .foregroundStyle(Theme.text)
                .tint(Theme.orange)
                .lineLimit(2...3)
                .focused($focused)
                .onChange(of: game.punishment) {
                    if game.punishment.count > game.maxPunishmentLength {
                        game.punishment = String(game.punishment.prefix(game.maxPunishmentLength))
                    }
                }
            HStack {
                Text("Whoever's holding it when it blows does it.")
                    .font(.fredoka(13))
                    .foregroundStyle(Theme.textFaint)
                Spacer()
                Text("\(game.punishment.count)/\(game.maxPunishmentLength)")
                    .font(.fredoka(13, .bold))
                    .foregroundStyle(Theme.textFaint)
                    .monospacedDigit()
            }
        }
        .glassCard(cornerRadius: 24, padding: 20)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Theme.fireGradient, lineWidth: 2)
                .opacity(focused ? 1 : 0)
        )
        .shadow(color: Theme.fire.opacity(focused ? 0.3 : 0), radius: 18)
        .onTapGesture { focused = true }
    }

    private var quickPicks: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Quick picks", color: Theme.textFaint, alignment: .leading)
            ScrollView(.horizontal) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(pickRows, id: \.self) { row in
                        HStack(spacing: 8) {
                            ForEach(row, id: \.self) { pick in
                                pickChip(pick)
                            }
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
        }
    }

    private func pickChip(_ pick: String) -> some View {
        let isPicked = game.punishment == pick
        return Button {
            SFX.play(.tap)
            Haptics.tap()
            focused = false
            withAnimation(.snappy) { game.punishment = pick }
        } label: {
            Text(pick)
                .font(.fredoka(15, .semibold))
                .foregroundStyle(isPicked ? Theme.bgBottom : Theme.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(Capsule().fill(isPicked ? AnyShapeStyle(Theme.goldGradient) : AnyShapeStyle(Theme.surface)))
                .overlay(Capsule().strokeBorder(Theme.stroke, lineWidth: isPicked ? 0 : 1))
        }
        .buttonStyle(.pressable)
    }
}

#Preview {
    let game = GameModel()
    for name in ["Mia", "Sam", "Lex"] { game.addPlayer(name) }
    game.holder = 1
    return PunishmentView(game: game)
}
