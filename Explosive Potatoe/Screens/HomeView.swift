import SwiftUI

struct HomeView: View {
    let game: GameModel
    @State private var showRules = false
    @State private var bob = false

    var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)

            VStack(spacing: -14) {
                Text("EXPLOSIVE")
                    .font(.lilita(50))
                    .foregroundStyle(Theme.red)
                    .shadow(color: Theme.ink, radius: 0, x: 0, y: 4)
                Text("POTATOE")
                    .font(.lilita(66))
                    .foregroundStyle(Theme.potatoDark)
                    .shadow(color: Theme.ink.opacity(0.25), radius: 0, x: 0, y: 4)
            }

            Text("Pass it. Panic. Don't be holding it.")
                .font(.fredoka(18))
                .foregroundStyle(Theme.inkMuted)

            ZStack {
                Circle()
                    .fill(Theme.yellow.opacity(0.35))
                    .frame(width: 270, height: 270)
                    .offset(y: -10)
                Ellipse()
                    .fill(Theme.ink.opacity(0.12))
                    .frame(width: 150, height: 22)
                    .offset(y: 146)
                PotatoImage(mood: .happy, width: 230)
                    .offset(y: bob ? -8 : 0)
            }
            .frame(height: 330)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever()) { bob = true }
            }

            Spacer(minLength: 0)

            Button("Start Game") { game.phase = .players }
                .buttonStyle(.chunky())
            Button("How to Play") { showRules = true }
                .buttonStyle(.chunky(.secondary))
                .padding(.top, 4)

            Text("Play responsibly · 18+ only")
                .font(.fredoka(13))
                .foregroundStyle(Theme.inkMuted)
                .padding(.top, 4)
        }
        .screen()
        .sheet(isPresented: $showRules) {
            HowToPlayView()
        }
    }
}

#Preview {
    HomeView(game: GameModel())
}
