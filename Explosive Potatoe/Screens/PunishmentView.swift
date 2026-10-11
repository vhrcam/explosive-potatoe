import SwiftUI

struct PunishmentView: View {
    @Bindable var game: GameModel
    @FocusState private var focused: Bool
    @State private var appeared = false
    @State private var rolls = 0

    private let pickTilts: [Double] = [-2, 1.5, -1, 2, -1.5, 1]

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
                        Avatar(name: setter.name, colorIndex: setter.colorIndex, size: 54)
                            .transition(.scale.combined(with: .opacity))
                    }
                    Text(setter.name)
                        .bigName(Theme.avatarColors[setter.colorIndex % Theme.avatarColors.count], size: 50)
                    Text("write the punishment")
                        .font(.fredoka(18, .semibold))
                        .foregroundStyle(Theme.textDim)
                }
                .staggerIn(appeared, 1)
            }

            noteCard
                .overlay(alignment: .topTrailing) {
                    PotatoSlot(width: 54)
                        .offset(x: 12, y: -52)
                }
                .padding(.top, 6)
                .staggerIn(appeared, 2)

            if !focused {
                quickPicks
                    .staggerIn(appeared, 3)
                    .transition(.opacity)
            }

            Spacer(minLength: 0)

            if !focused {
                HStack(spacing: 10) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(Theme.fire)
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
                .foregroundStyle(Theme.fire)
            Text("\(game.gameType.title.uppercased()) · ROUND \(game.round)/\(game.gameType.rounds)")
        }
        .font(.fredoka(13, .bold))
        .tracking(1.2)
        .foregroundStyle(Theme.text)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Capsule().fill(Theme.surfaceStrong))
        .overlay(Capsule().strokeBorder(Theme.stroke, lineWidth: 1))
        .shadow(color: Theme.shadow, radius: 3, y: 2)
    }

    private var noteCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("LOSER HAS TO…")
                    .font(.fredoka(13, .bold))
                    .tracking(1.4)
                    .foregroundStyle(Theme.fire)
                Spacer()
                Button {
                    rolls += 1
                    SFX.play(.flip)
                    Haptics.tap()
                    withAnimation(.snappy) { game.randomPunishment() }
                } label: {
                    Image(systemName: "dice.fill")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(Theme.card))
                        .overlay(Circle().strokeBorder(Theme.stroke, lineWidth: 1))
                        .shadow(color: Theme.shadow, radius: 3, y: 2)
                        .rotationEffect(.degrees(Double(rolls) * 360))
                        .animation(.spring(duration: 0.6, bounce: 0.35), value: rolls)
                }
                .buttonStyle(.pressable)
            }
            TextField("Punishment", text: $game.punishment, prompt: Text("Write it here, or roll the dice").foregroundStyle(Theme.textFaint), axis: .vertical)
                .font(.hand(32))
                .foregroundStyle(Theme.ink)
                .tint(Theme.fire)
                .lineLimit(2...3)
                .focused($focused)
                .onChange(of: game.punishment) {
                    if game.punishment.count > game.maxPunishmentLength {
                        game.punishment = String(game.punishment.prefix(game.maxPunishmentLength))
                    }
                }
            HStack(alignment: .firstTextBaseline) {
                Text(game.punishmentHint)
                    .font(.fredoka(13))
                    .foregroundStyle(Theme.textDim)
                Spacer()
                Text("\(game.punishment.count)/\(game.maxPunishmentLength)")
                    .font(.fredoka(13, .bold))
                    .foregroundStyle(Theme.textFaint)
                    .monospacedDigit()
            }
        }
        .noteCard(rotation: focused ? 0 : -1.5)
        .scaleEffect(focused ? 1.02 : 1)
        .onTapGesture { focused = true }
    }

    private var quickPicks: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Quick picks", color: Theme.textFaint, alignment: .leading)
            ScrollView(.horizontal) {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(pickRows.enumerated()), id: \.offset) { r, row in
                        HStack(spacing: 10) {
                            ForEach(Array(row.enumerated()), id: \.element) { c, pick in
                                pickCard(pick, tilt: pickTilts[(r * 3 + c) % pickTilts.count])
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
        }
    }

    private func pickCard(_ pick: String, tilt: Double) -> some View {
        let isPicked = game.punishment == pick
        return Button {
            SFX.play(.tap)
            Haptics.tap()
            focused = false
            withAnimation(.snappy) { game.punishment = pick }
        } label: {
            Text(pick)
                .font(.hand(21))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(isPicked ? Theme.yellow.opacity(0.45) : Theme.card))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(isPicked ? Theme.orange : Theme.stroke, lineWidth: isPicked ? 1.5 : 1)
                )
                .shadow(color: Theme.shadow, radius: 2, y: 2)
                .rotationEffect(.degrees(isPicked ? 0 : tilt))
                .scaleEffect(isPicked ? 1.06 : 1)
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
