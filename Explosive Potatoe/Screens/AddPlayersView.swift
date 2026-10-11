import SwiftUI

struct AddPlayersView: View {
    let game: GameModel
    @State private var newName = ""
    @State private var warning: String?
    @State private var rejects = 0
    @State private var appeared = false
    @FocusState private var nameFocused: Bool

    private let maxNameLength = 14

    private var trimmed: String { newName.trimmingCharacters(in: .whitespaces) }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                CircleIconButton(systemName: "chevron.left") { game.phase = .players }
                Spacer()
                PlayerCountChip(count: game.players.count, minimum: game.minPlayers, maximum: game.maxPlayers)
            }
            .staggerIn(appeared, 0)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Add players")
                        .font(.lilita(38))
                        .foregroundStyle(Theme.text)
                    Text(game.isFull ? "That's a full house!" : "Names show up big when it's your turn.")
                        .font(.fredoka(15))
                        .foregroundStyle(Theme.textDim)
                }
                Spacer()
                PotatoImage(mood: .happy, width: 60)
                    .rotationEffect(.degrees(8))
                    .keyframeAnimator(initialValue: CGFloat(0), trigger: game.players.count) { content, hop in
                        content.offset(y: hop)
                    } keyframes: { _ in
                        KeyframeTrack {
                            SpringKeyframe(-16, duration: 0.14)
                            SpringKeyframe(0, duration: 0.4, spring: .bouncy)
                        }
                    }
            }
            .staggerIn(appeared, 1)

            VStack(alignment: .leading, spacing: 8) {
                nameField
                    .jolt(rejects, strength: 0.6)
                if let warning {
                    Text(warning)
                        .font(.fredoka(14, .semibold))
                        .foregroundStyle(Theme.fire)
                        .padding(.leading, 8)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .staggerIn(appeared, 2)

            if !game.players.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    SectionLabel(text: "In the game", color: Theme.textFaint, alignment: .leading)
                    ScrollView {
                        FlowLayout(spacing: 8) {
                            ForEach(game.players) { player in
                                PlayerChip(player: player) {
                                    withAnimation(.spring(duration: 0.35, bounce: 0.3)) { game.removePlayer(player) }
                                }
                                .transition(.scale(scale: 0.3).combined(with: .opacity))
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .scrollIndicators(.hidden)
                    .frame(maxHeight: 200)
                    .fixedSize(horizontal: false, vertical: true)
                }
                .transition(.opacity)
            }

            Spacer(minLength: 0)

            if game.hasEnoughPlayers {
                Button { game.phase = .players } label: {
                    Label("Done", systemImage: "checkmark")
                }
                .buttonStyle(.chunky(.green))
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .screen()
        .onAppear {
            appeared = true
            nameFocused = true
        }
        .onChange(of: newName) {
            if newName.count > maxNameLength {
                newName = String(newName.prefix(maxNameLength))
            }
            withAnimation(.easeOut(duration: 0.2)) { warning = nil }
        }
    }

    private var nameField: some View {
        HStack(spacing: 10) {
            TextField("Name", text: $newName, prompt: Text("Player name").foregroundStyle(Theme.textFaint))
                .font(.fredoka(22, .semibold))
                .foregroundStyle(Theme.text)
                .tint(Theme.orange)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .focused($nameFocused)
                .submitLabel(.done)
                .onSubmit(add)
            Button(action: add) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(Circle().fill(Theme.fireGradient))
                    .shadow(color: Theme.fire.opacity(trimmed.isEmpty ? 0 : 0.6), radius: 10)
            }
            .buttonStyle(.pressable)
            .opacity(trimmed.isEmpty ? 0.35 : 1)
            .scaleEffect(trimmed.isEmpty ? 0.85 : 1)
            .animation(.spring(duration: 0.3, bounce: 0.5), value: trimmed.isEmpty)
        }
        .padding(.leading, 20)
        .padding(.trailing, 8)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Theme.surfaceStrong))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(nameFocused ? AnyShapeStyle(Theme.fireGradient) : AnyShapeStyle(Theme.stroke), lineWidth: nameFocused ? 2 : 1)
        )
        .shadow(color: Theme.fire.opacity(nameFocused ? 0.3 : 0), radius: 16)
        .animation(.easeOut(duration: 0.2), value: nameFocused)
    }

    private func add() {
        nameFocused = true
        guard !trimmed.isEmpty else { return }
        let taken = game.players.contains { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }
        if taken || game.isFull {
            rejects += 1
            SFX.play(.fail)
            Haptics.fail()
            withAnimation(.spring(duration: 0.3)) {
                warning = game.isFull ? "\(game.maxPlayers) players max" : "\(trimmed) is already in"
            }
            return
        }
        withAnimation(.spring(duration: 0.45, bounce: 0.45)) { game.addPlayer(trimmed) }
        newName = ""
        SFX.play(.pop, pitch: .random(in: 0.9...1.2))
        Haptics.tap()
    }
}

private struct PlayerChip: View {
    let player: Player
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Avatar(name: player.name, colorIndex: player.colorIndex, size: 28)
            Text(player.name)
                .font(.fredoka(16, .semibold))
                .foregroundStyle(Theme.text)
            Button {
                SFX.play(.tap)
                Haptics.tap()
                onRemove()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.textDim)
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.pressable)
        }
        .padding(.leading, 6)
        .padding(.trailing, 8)
        .padding(.vertical, 6)
        .background(Capsule().fill(Theme.surfaceStrong))
        .overlay(Capsule().strokeBorder(Theme.stroke, lineWidth: 1))
    }
}

#Preview {
    let game = GameModel()
    for name in ["Mia", "Sam", "Lex"] { game.addPlayer(name) }
    return AddPlayersView(game: game)
}
