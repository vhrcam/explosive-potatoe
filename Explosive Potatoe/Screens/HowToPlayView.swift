import SwiftUI

struct HowToPlayView: View {
    let game: GameModel
    @Environment(\.dismiss) private var dismiss
    @State private var appeared = false

    private let scoring = [
        ("Catch in under 0.5s", "+15"),
        ("Catch in under 1s", "+10"),
        ("Slower catch", "+5"),
        ("Pass the potato", "+10"),
        ("Beat a minigame", "+15"),
        ("Forced on you after 1.5s", "−10")
    ]

    private var rules: [Rule] {
        let modes = GameType.allCases.map { "\($0.title) (\($0.rounds))" }.formatted(.list(type: .or))
        return [
            Rule(symbol: "person.3.fill", color: Theme.blue, title: "Gather the crew", text: "\(game.minPlayers) to \(game.maxPlayers) players. Pick a mode: \(modes) rounds."),
            Rule(symbol: "pencil.line", color: Theme.purple, title: "Set the stakes", text: "A random player writes the punishment. Whoever's holding the potato when it blows has to do it."),
            Rule(symbol: "flame.fill", color: Theme.fire, title: "Secret fuse", text: "Nobody knows how long it is, and it never stops. Not for minigames, not for anything."),
            Rule(symbol: "hand.point.up.left.fill", color: Theme.orange, title: "Flick to throw", text: "Flick the potato up to throw it to the named player. Time slows down while it flies."),
            Rule(symbol: "hand.raised.fill", color: Theme.green, title: "Catch it fast", text: "Tap CATCH the second it's yours. Wait 1.5s and it's forced on you."),
            Rule(symbol: "suit.spade.fill", color: Theme.pink, title: "Card roulette", text: "Every catch flips a card: safe or minigame. Six minigames, and the fuse keeps burning while you play."),
            Rule(symbol: "burst.fill", color: Theme.yellow, title: "Boom", text: "Holding it when it blows? Do the punishment, then write the next one."),
            Rule(symbol: "trophy.fill", color: Theme.orange, title: "Win", text: "Most points after the last round wins. Ties go to whoever exploded less.")
        ]
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
            SectionLabel(text: "Scoring", color: Theme.yellow, alignment: .leading)
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
                .shadow(color: rule.color.opacity(0.5), radius: 8)
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
