import SwiftUI

struct HowToPlayView: View {
    let game: GameModel
    @Environment(\.dismiss) private var dismiss
    @State private var appeared = false

    private var scoring: [(String, String)] {
        let catches = game.catchTiers.map { tier in
            (tier.time.isFinite ? "Catch in under \(seconds(tier.time))" : "Slower catch", "+\(tier.points)")
        }
        return catches + [
            ("Pass the potato", "+\(game.passPoints)"),
            ("Beat a minigame", "+\(game.minigamePoints)"),
            ("Not caught in \(seconds(game.autoGiveTime))", "−\(game.lateGivePenalty)")
        ]
    }

    private var rules: [Rule] {
        let modes = GameType.allCases.map { "\($0.title) (\($0.rounds))" }.formatted(.list(type: .or))
        return [
            Rule(symbol: "person.3.fill", color: Theme.blue, title: "Gather the crew", text: "\(game.minPlayers) to \(game.maxPlayers) players. Pick a mode: \(modes) rounds."),
            Rule(symbol: "pencil.line", color: Theme.purple, title: "Set the stakes", text: "A random player writes the punishment on a card. Before the final round it lasts all next round, like talking in an accent. In the final round or Quick Blast it's a one-time dare done right after the boom."),
            Rule(symbol: "flame.fill", color: Theme.fire, title: "Secret fuse", text: "Nobody knows how long it is, and it never stops. Not for minigames, not for anything."),
            Rule(symbol: "hand.point.up.left.fill", color: Theme.orange, title: "Flick to throw", text: "No buttons. Flick the potato up off the screen to throw it to the named player. Time slows down while it flies."),
            Rule(symbol: "iphone.radiowaves.left.and.right", color: Theme.green, title: "Shake to catch", text: "Grab the phone and shake it to catch, or swipe the potato down. Faster catches score more. After \(seconds(game.autoGiveTime)) it's forced on you."),
            Rule(symbol: "suit.spade.fill", color: Theme.pink, title: "Card roulette", text: "Every catch flips a card on its own: safe or minigame. \(Minigame.allCases.count) minigames, and the fuse keeps burning while you play."),
            Rule(symbol: "burst.fill", color: Theme.yellow, title: "Boom", text: "Holding it when it blows? The punishment is yours. Then you write the next card."),
            Rule(symbol: "trophy.fill", color: Theme.orange, title: "Win", text: "Most points after the last round wins. Ties go to whoever exploded less.")
        ]
    }

    private func seconds(_ time: Double) -> String {
        time.formatted(.number.precision(.fractionLength(0...1))) + "s"
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("How to Play")
                    .font(.lilita(36))
                    .foregroundStyle(Theme.text)
                Spacer()
                CircleIconButton(systemName: "xmark") { dismiss() }
            }

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Array(rules.enumerated()), id: \.offset) { index, rule in
                        RuleRow(rule: rule)
                            .staggerIn(appeared, index)
                    }
                    scoringCard
                        .staggerIn(appeared, rules.count)
                }
                .padding(.bottom, 8)
            }
            .scrollIndicators(.hidden)

            Button { dismiss() } label: {
                Label("Got It", systemImage: "checkmark")
            }
            .buttonStyle(.chunky())
        }
        .padding(.top, 16)
        .screen()
        .presentationDragIndicator(.visible)
        .onAppear { appeared = true }
    }

    private var scoringCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Scoring", color: Theme.fire, alignment: .leading)
            ForEach(scoring, id: \.0) { label, points in
                HStack {
                    Text(label)
                        .font(.fredoka(16))
                        .foregroundStyle(Theme.text)
                    Spacer()
                    Text(points)
                        .font(.fredoka(16, .bold))
                        .foregroundStyle(points.hasPrefix("+") ? Theme.green : Theme.fire)
                        .monospacedDigit()
                }
            }
            Rectangle()
                .fill(Theme.stroke)
                .frame(height: 1)
                .padding(.vertical, 4)
            Text("Awards at the end: Hot Hands, Lightning, Boom Magnet and Minigame Master.")
                .font(.fredoka(14))
                .foregroundStyle(Theme.textDim)
                .fixedSize(horizontal: false, vertical: true)
        }
        .glassCard(cornerRadius: 20, padding: 18)
    }
}

private struct Rule {
    let symbol: String
    let color: Color
    let title: String
    let text: String
}

private struct RuleRow: View {
    let rule: Rule

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: rule.symbol)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(Circle().fill(rule.color.gradient))
                .shadow(color: Theme.ink.opacity(0.2), radius: 2, x: 0, y: 2)
            VStack(alignment: .leading, spacing: 3) {
                Text(rule.title)
                    .font(.lilita(20))
                    .foregroundStyle(Theme.text)
                Text(rule.text)
                    .font(.fredoka(15))
                    .foregroundStyle(Theme.textDim)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .glassCard(cornerRadius: 20, padding: 16)
    }
}

#Preview {
    HowToPlayView(game: GameModel())
}
