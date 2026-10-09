import SwiftUI

struct Player: Identifiable {
    let id = UUID()
    var name: String
    var colorIndex: Int
    var points = 0
    var losses = 0
}

enum GameType: String, CaseIterable, Identifiable {
    case threeRounds = "3-Round Game"

    var id: Self { self }

    var rounds: Int {
        switch self {
        case .threeRounds: 3
        }
    }
}

enum Minigame: CaseIterable {
    case tapNumbers, sortCrates, fillBucket, holdRelease

    var cardHint: String {
        switch self {
        case .tapNumbers: "Tap 1 → 9 in order"
        case .sortCrates: "Sort the crates"
        case .fillBucket: "Fill the bucket"
        case .holdRelease: "Hold & release"
        }
    }
}

@Observable
final class GameModel {
    enum Phase { case home, players, addPlayers, punishment, playing, exploded, results }
    enum Step: Equatable { case card(Minigame?), minigame(Minigame), holding, passing }

    let minPlayers = 3
    let maxPunishmentLength = 80
    let quickPicks = ["Sing a chorus", "10 push-ups", "Swap seats", "Talk in an accent"]
    let autoGiveTime = 1.5
    let passPoints = 20
    let earlyAcceptPoints = 10
    let lateGivePenalty = 10
    let minigamePoints = 10

    private let minigameChance = 0.3
    private let surpriseChance = 0.05
    private let surpriseMin = 5.0
    private let slowMoEnd = 2.0

    var players: [Player] = []
    var gameType = GameType.threeRounds
    var phase = Phase.home
    var step = Step.holding
    var round = 1
    var punishment = ""
    var holder = 0
    var passer = 0
    var target = 0
    var potatoTime = 0.0
    var passElapsed = 0.0
    var isSlowMo = false
    var cardLabel = ""
    var turn = 0
    private(set) var passPending = false

    private var fuse = 60.0
    private var passStart: Date?
    private var nextColor = 0
    @ObservationIgnored private var lastTick = Date.now
    @ObservationIgnored private var loop: Task<Void, Never>?

    var isLastRound: Bool { round == gameType.rounds }
    var ranked: [Player] { players.sorted { $0.points > $1.points } }
    var hasEnoughPlayers: Bool { players.count >= minPlayers }

    var fuseText: String {
        let seconds = Int(potatoTime)
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    func name(_ index: Int) -> String {
        players[index].name
    }

    func addPlayer(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        players.append(Player(name: trimmed, colorIndex: nextColor))
        nextColor += 1
    }

    func removePlayer(_ player: Player) {
        players.removeAll { $0.id == player.id }
    }

    func startGame() {
        for i in players.indices {
            players[i].points = 0
            players[i].losses = 0
        }
        round = 1
        punishment = ""
        holder = players.indices.randomElement() ?? 0
        phase = .punishment
    }

    func startRound() {
        fuse = randomFuse()
        potatoTime = 0
        passStart = nil
        passPending = false
        isSlowMo = false
        turn += 1
        cardLabel = "\(name(holder)) lit the fuse"
        step = .card(rollMinigame())
        phase = .playing
        lastTick = .now
        loop = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(16))
                tick()
            }
        }
    }

    func cardDone() {
        if case .card(let minigame?) = step {
            step = .minigame(minigame)
        } else {
            readyToPass()
        }
    }

    func minigameDone() {
        players[holder].points += minigamePoints
        readyToPass()
    }

    func pass() {
        players[holder].points += passPoints
        passer = holder
        passStart = .now
        passElapsed = 0
        passPending = true
        isSlowMo = true
        step = .passing
    }

    func accept() {
        if passPending {
            players[target].points += earlyAcceptPoints
            holder = target
            passPending = false
            cardLabel = "\(name(holder)) accepted · +\(earlyAcceptPoints)"
        } else {
            cardLabel = "\(name(holder)) was too slow · −\(lateGivePenalty)"
        }
        turn += 1
        step = .card(rollMinigame())
    }

    func finishPunishment() {
        if isLastRound {
            phase = .results
        } else {
            round += 1
            punishment = ""
            phase = .punishment
        }
    }

    private func readyToPass() {
        target = players.indices.filter { $0 != holder }.randomElement() ?? holder
        step = .holding
    }

    private func rollMinigame() -> Minigame? {
        Double.random(in: 0..<1) < minigameChance ? Minigame.allCases.randomElement() : nil
    }

    private func randomFuse() -> Double {
        if Double.random(in: 0..<1) < surpriseChance {
            return Double.random(in: surpriseMin..<20)
        }
        return 25 + 125 * pow(Double.random(in: 0...1), 2.5)
    }

    private func speed(at now: Date) -> Double {
        guard let passStart else { return 1 }
        let t = now.timeIntervalSince(passStart)
        if t < autoGiveTime { return 0.5 }
        return min(0.5 + 0.5 * (t - autoGiveTime) / (slowMoEnd - autoGiveTime), 1)
    }

    private func tick() {
        guard phase == .playing else { return }
        let now = Date.now
        potatoTime += now.timeIntervalSince(lastTick) * speed(at: now)
        lastTick = now

        if let passStart {
            let t = now.timeIntervalSince(passStart)
            passElapsed = min(t, autoGiveTime)
            if passPending && t >= autoGiveTime {
                players[target].points -= lateGivePenalty
                holder = target
                passPending = false
            }
            if t >= slowMoEnd {
                self.passStart = nil
                isSlowMo = false
            }
        }

        if potatoTime >= fuse { explode() }
    }

    private func explode() {
        loop?.cancel()
        passStart = nil
        passPending = false
        isSlowMo = false
        players[holder].losses += 1
        phase = .exploded
    }
}
