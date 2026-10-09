import SwiftUI

struct HowToPlayView: View {
    @Environment(\.dismiss) private var dismiss

    private let rules = [
        "Add 3 or more players. A random one types the first punishment.",
        "Light the fuse. Nobody knows how long it is.",
        "When it's passed to you, tap \"It's you!\" fast for +10. Too slow and it's forced on you for −10.",
        "A card decides: minigame or safe. Beat the minigame for +10.",
        "Pass it on for +20. Passing slows time down. The fuse never stops.",
        "Holding it when it blows? Do the punishment, then set the next one.",
        "After 3 rounds, the most points wins."
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("How to Play")
                .font(.lilita(40))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(rules.indices, id: \.self) { i in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(i + 1)")
                                .font(.fredoka(15, .bold))
                                .foregroundStyle(.white)
                                .frame(width: 30, height: 30)
                                .background(Circle().fill(Theme.red))
                                .overlay(Circle().strokeBorder(Theme.ink, lineWidth: 2))
                            Text(rules[i])
                                .font(.fredoka(17))
                                .foregroundStyle(Theme.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            Button("Got it") { dismiss() }
                .buttonStyle(.chunky())
        }
        .padding(.top, 20)
        .screen()
    }
}

#Preview {
    HowToPlayView()
}
