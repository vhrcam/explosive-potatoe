import SwiftUI

struct Player: Identifiable {
    let id = UUID()
    var name: String
    var colorIndex: Int
    var points = 0
    var losses = 0
    var passes = 0
    var minigamesWon = 0
    var fastestCatch: Double?
}

enum GameType: String, CaseIterable, Identifiable {
    case quickBlast, classic, marathon

    var id: Self { self }

    var title: String {
        switch self {
        case .quickBlast: "Quick Blast"
        case .classic: "Classic"
        case .marathon: "Marathon"
        }
    }

    var blurb: String {
        switch self {
        case .quickBlast: "One fuse. One loser."
        case .classic: "Three rounds, points decide it."
        case .marathon: "Five rounds of pure panic."
        }
    }

    var rounds: Int {
        switch self {
        case .quickBlast: 1
        case .classic: 3
        case .marathon: 5
        }
    }

    var symbol: String {
        switch self {
        case .quickBlast: "bolt.fill"
        case .classic: "flame.fill"
        case .marathon: "infinity"
        }
    }
}

enum Minigame: CaseIterable {
    case tapNumbers, sortCrates, fillBucket, holdRelease, arrowRush, cutWire

    var cardHint: String {
        switch self {
        case .tapNumbers: "Tap 1 → 9 in order"
        case .sortCrates: "Sort the crates"
        case .fillBucket: "Fill the bucket"
        case .holdRelease: "Hold & release"
        case .arrowRush: "Swipe the arrows"
        case .cutWire: "Cut the right wire"
        }
    }

    var symbol: String {
        switch self {
        case .tapNumbers: "number"
        case .sortCrates: "shippingbox.fill"
        case .fillBucket: "drop.fill"
        case .holdRelease: "hand.tap.fill"
        case .arrowRush: "arrow.up.and.down.and.arrow.left.and.right"
        case .cutWire: "scissors"
        }
    }
}

struct Award: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let symbol: String
    let playerName: String
    let colorIndex: Int
}

@Observable
final class GameModel {
    enum Phase { case home, players, addPlayers, punishment, playing, exploded, results }
    enum Step: Equatable { case card(Minigame?), minigame(Minigame), holding, passing }

    let minPlayers = 3
    let maxPlayers = 12
    let maxPunishmentLength = 80
    let nextRoundPicks = [
        "British accent all next round", "Pass with your weak hand next round", "Stand up all next round",
        "No saying names next round", "Narrate everything next round", "Only ask questions next round",
        "Shout \"HOT!\" every pass next round", "Sit on the floor next round", "Whisper all next round",
        "Robot voice all next round", "No laughing next round", "Talk like a pirate all next round",
        "Hum while holding it next round", "Compliment whoever you pass to next round",
        "One leg up while holding it next round", "Call everyone \"captain\" next round"
    ]
    let oneShotPicks = [
        "Do 15 push-ups", "Sing a full chorus out loud", "Plank for 30 seconds", "Do 20 jumping jacks",
        "Tell your most embarrassing story", "Do an impression the group picks", "Dance for 15 seconds, no music",
        "Compliment every player", "Talk like a pirate for 1 minute", "Freestyle rap 4 bars",
        "Wall sit for 30 seconds", "Act like a chicken for 10 seconds", "Speak in rhymes for 1 minute",
        "Do your best runway walk", "Do 10 squats", "Give a 30-second motivational speech"
    ]
    let autoGiveTime = 2.0
    let passPoints = 10
    let lateGivePenalty = 10
    let minigamePoints = 15
    let catchTiers: [(time: Double, points: Int, label: String)] = [(0.7, 15, "Lightning catch"), (1.3, 10, "Quick catch"), (.infinity, 5, "Caught")]

    private let minigameChance = 0.3
    private let surpriseChance = 0.05
    private let surpriseMin = 6.0
    private let slowMoEnd = 2.5

    var players: [Player] = []
    var gameType = GameType.classic
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
    var potatoPokes = 0
    var potatoDrag = CGSize.zero
    var turn = 0
    var lastCatch: (points: Int, label: String)?
    private(set) var passPending = false

    private var fuse = 60.0
    private var passStart: Date?
    private var nextColor = 0
    private var nextHeartbeat = 0.0
    @ObservationIgnored private var lastTick = Date.now
    @ObservationIgnored private var loop: Task<Void, Never>?

    var isLastRound: Bool { round >= gameType.rounds }
    var punishmentIsNextRound: Bool { !isLastRound }
    var quickPicks: [String] { punishmentIsNextRound ? nextRoundPicks : oneShotPicks }

    var punishmentHint: String {
        let who = phase == .exploded ? name(holder) : "The loser"
        return punishmentIsNextRound
            ? "\(who) does it all through round \(round + 1)."
            : "\(who) does it right after the boom."
    }
    var hasEnoughPlayers: Bool { players.count >= minPlayers }
    var isFull: Bool { players.count >= maxPlayers }

    var ranked: [Player] {
        players.sorted { $0.points != $1.points ? $0.points > $1.points : $0.losses < $1.losses }
    }

    var fuseText: String {
        let seconds = Int(potatoTime)
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    var awards: [Award] {
        var list: [Award] = []
        if let p = players.max(by: { $0.passes < $1.passes }), p.passes > 0 {
            list.append(Award(title: "Hot Hands", detail: "\(p.passes) passes", symbol: "hands.sparkles.fill", playerName: p.name, colorIndex: p.colorIndex))
        }
        if let p = players.filter({ $0.fastestCatch != nil }).min(by: { $0.fastestCatch! < $1.fastestCatch! }), let time = p.fastestCatch {
            list.append(Award(title: "Lightning", detail: String(format: "%.2fs catch", time), symbol: "bolt.fill", playerName: p.name, colorIndex: p.colorIndex))
        }
        if let p = players.max(by: { $0.losses < $1.losses }), p.losses > 0 {
            list.append(Award(title: "Boom Magnet", detail: "blew up \(p.losses)×", symbol: "flame.fill", playerName: p.name, colorIndex: p.colorIndex))
        }
        if let p = players.max(by: { $0.minigamesWon < $1.minigamesWon }), p.minigamesWon > 0 {
            list.append(Award(title: "Minigame Master", detail: "\(p.minigamesWon) cleared", symbol: "gamecontroller.fill", playerName: p.name, colorIndex: p.colorIndex))
        }
        return list
    }

    func name(_ index: Int) -> String {
        players.indices.contains(index) ? players[index].name : ""
    }

    func addPlayer(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !isFull else { return }
        players.append(Player(name: trimmed, colorIndex: nextColor))
        nextColor += 1
    }

    func removePlayer(_ player: Player) {
        players.removeAll { $0.id == player.id }
    }

    func randomPunishment() {
        punishment = quickPicks.filter { $0 != punishment }.randomElement() ?? ""
    }

    func startGame() {
        resetStats()
        holder = players.indices.randomElement() ?? 0
        phase = .punishment
    }

    func newGame() {
        resetStats()
        phase = .players
    }

    func startRound() {
        fuse = randomFuse()
        potatoTime = 0
        passStart = nil
        passPending = false
        isSlowMo = false
        lastCatch = nil
        potatoDrag = .zero
        nextHeartbeat = 0
        turn += 1
        cardLabel = "\(name(holder)) lit the fuse"
        step = .card(rollMinigame())
        phase = .playing
        SFX.startSizzle()
        lastTick = .now
        loop?.cancel()
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
        players[holder].minigamesWon += 1
        readyToPass()
    }

    func pass() {
        guard step == .holding else { return }
        players[holder].points += passPoints
        players[holder].passes += 1
        passer = holder
        passStart = .now
        passElapsed = 0
        passPending = true
        isSlowMo = true
        step = .passing
        SFX.play(.whoosh)
        Haptics.heavy()
    }

    func accept() {
        guard step == .passing else { return }
        if passPending, let passStart {
            let time = Date.now.timeIntervalSince(passStart)
            let tier = catchTiers.first { time < $0.time } ?? catchTiers[catchTiers.count - 1]
            players[target].points += tier.points
            if time < players[target].fastestCatch ?? .infinity {
                players[target].fastestCatch = time
            }
            holder = target
            passPending = false
            lastCatch = (tier.points, tier.label)
            cardLabel = "\(name(holder)) · \(tier.label.lowercased())"
            SFX.play(.grab)
            Haptics.success()
        } else {
            lastCatch = (-lateGivePenalty, "Too slow")
            cardLabel = "\(name(holder)) was too slow"
            Haptics.fail()
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

    func quit() {
        loop?.cancel()
        SFX.stopSizzle()
        phase = .home
    }

    private func resetStats() {
        for i in players.indices {
            players[i].points = 0
            players[i].losses = 0
            players[i].passes = 0
            players[i].minigamesWon = 0
            players[i].fastestCatch = nil
        }
        round = 1
        punishment = ""
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
                Haptics.fail()
                SFX.play(.fail)
            }
            if t >= slowMoEnd {
                self.passStart = nil
                isSlowMo = false
            }
        }

        if step == .holding && potatoTime >= nextHeartbeat {
            Haptics.heartbeat()
            nextHeartbeat = potatoTime + max(0.45, 1.2 - potatoTime / 100)
        }

        if potatoTime >= fuse { explode() }
    }

    private func explode() {
        loop?.cancel()
        passStart = nil
        passPending = false
        isSlowMo = false
        players[holder].losses += 1
        SFX.stopSizzle()
        phase = .exploded
    }
}
