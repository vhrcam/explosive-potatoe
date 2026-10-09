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
        .animation(.easeInOut(duration: 0.25), value: game.phase)
    }
}

#Preview {
    ContentView()
}
