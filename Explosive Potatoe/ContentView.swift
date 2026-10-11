//
//  ContentView.swift
//  Explosive Potatoe
//
//  Created by cam  on 10/7/26.
//

import SwiftUI

struct ContentView: View {
    @State private var game = GameModel()

    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.bgTop, Theme.bgBottom], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            Group {
                switch game.phase {
                case .home: HomeView(game: game)
                case .players: PlayersView(game: game)
                case .addPlayers: AddPlayersView(game: game)
                case .punishment: PunishmentView(game: game)
                case .playing: GameView(game: game)
                case .exploded: ExplosionView(game: game)
                case .results: ResultsView(game: game)
                }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.97)))
        }
        .potatoStage(game)
        .animation(.easeInOut(duration: 0.3), value: game.phase)
        .preferredColorScheme(.light)
        .tint(Theme.fire)
    }
}

#Preview {
    ContentView()
}
