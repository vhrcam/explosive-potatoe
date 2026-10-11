import SwiftUI

struct HomeView: View {
    let game: GameModel
    @State private var showRules = false
    @State private var appeared = false
    @State private var muted = SFX.isMuted

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Spacer()
                CircleIconButton(systemName: muted ? "speaker.slash.fill" : "speaker.wave.2.fill") {
                    muted.toggle()
                    SFX.isMuted = muted
                }
            }
            .staggerIn(appeared, 0)

            Spacer(minLength: 0)

            VStack(spacing: -12) {
                Text("EXPLOSIVE")
                    .font(.lilita(40))
                    .tracking(4)
                    .foregroundStyle(Theme.goldGradient)
                Text("POTATOE")
                    .font(.lilita(76))
                    .foregroundStyle(Theme.fireGradient)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .shadow(color: Theme.ink.opacity(0.85), radius: 0, x: 0, y: 4)
            .staggerIn(appeared, 1)

            Text("Pass it. Panic. Don't be holding it.")
                .font(.fredoka(17))
                .foregroundStyle(Theme.textDim)
                .staggerIn(appeared, 2)

            PotatoSlot(width: 190)
                .frame(height: 290)
                .contentShape(Rectangle())
                .onTapGesture {
                    game.potatoPokes += 1
                    SFX.play(.pop, pitch: .random(in: 0.85...1.25))
                    Haptics.tap()
                }

            Spacer(minLength: 0)

            VStack(spacing: 12) {
                Button { game.phase = .players } label: {
                    Label("Start Game", systemImage: "flame.fill")
                }
                .buttonStyle(.chunky())
                Button { showRules = true } label: {
                    Label("How to Play", systemImage: "questionmark.circle.fill")
                }
                .buttonStyle(.chunky(.secondary))
            }
            .staggerIn(appeared, 4)

            Text("Play responsibly · 18+ only")
                .font(.fredoka(13))
                .foregroundStyle(Theme.textFaint)
                .staggerIn(appeared, 5)
        }
        .screen()
        .onAppear { appeared = true }
        .sheet(isPresented: $showRules) {
            HowToPlayView(game: game)
        }
    }
}

#Preview {
    HomeView(game: GameModel())
}
