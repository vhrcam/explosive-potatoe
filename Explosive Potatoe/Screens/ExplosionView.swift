import SwiftUI

struct ExplosionView: View {
    let game: GameModel
    @State private var popped = false

    var body: some View {
        VStack(spacing: 16) {
            Text("BOOM!")
                .font(.lilita(100))
                .foregroundStyle(.white)
                .shadow(color: Theme.ink, radius: 0, x: 0, y: 6)
                .rotationEffect(.degrees(-4))
                .minimumScaleFactor(0.6)
                .padding(.top, 20)

            PotatoImage(mood: .boom, width: 210)
                .frame(height: 290)

            VStack(spacing: 8) {
                SectionLabel(text: "\(game.name(game.holder)) exploded · do the punishment", color: Theme.red)
                Text(game.punishment)
                    .font(.fredoka(22))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 22)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 22).fill(.white))
            .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Theme.ink, lineWidth: 3))
            .background(RoundedRectangle(cornerRadius: 22).fill(Theme.ink).offset(y: 6))

            Spacer(minLength: 0)

            Button(game.isLastRound ? "Done · see results" : "Done · set next punishment") {
                game.finishPunishment()
            }
            .buttonStyle(.chunky(.secondary))
        }
        .scaleEffect(popped ? 1 : 0.85)
        .padding(.horizontal, 32)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(BoomBackground(popped: popped))
        .sensoryFeedback(.impact(weight: .heavy, intensity: 1), trigger: popped)
        .onAppear {
            withAnimation(.spring(duration: 0.45, bounce: 0.5)) { popped = true }
        }
    }
}

private struct BoomBackground: View {
    let popped: Bool

    var body: some View {
        ZStack {
            Theme.red
            ZStack {
                StarburstShape(points: 14, innerRatio: 0.62, irregular: true)
                    .fill(Color(hex: 0xFF8A3D))
                    .frame(width: 600, height: 600)
                StarburstShape(points: 12, innerRatio: 0.6, irregular: true)
                    .fill(Theme.yellow)
                    .overlay(
                        StarburstShape(points: 12, innerRatio: 0.6, irregular: true)
                            .stroke(Theme.ink, style: StrokeStyle(lineWidth: 4, lineJoin: .round))
                    )
                    .frame(width: 440, height: 440)
                StarburstShape(points: 10, innerRatio: 0.65, irregular: true)
                    .fill(Color(hex: 0xFFF3B0))
                    .frame(width: 240, height: 240)
            }
            .scaleEffect(popped ? 1 : 0.3)
            .rotationEffect(.degrees(popped ? 0 : -30))
            .offset(y: -80)

            Sparkle(size: 32, fill: Color(hex: 0xFFF3B0)).offset(x: -140, y: -310)
            Sparkle(size: 16, fill: Color(hex: 0xFFF3B0)).offset(x: 112, y: -330)
            Sparkle(size: 24, fill: Color(hex: 0xFFF3B0)).offset(x: 146, y: -230)
            Sparkle(size: 36, fill: Color(hex: 0xFFF3B0)).offset(x: 160, y: 110)
            Sparkle(size: 20, fill: Color(hex: 0xFFF3B0)).offset(x: -130, y: 150)
        }
        .ignoresSafeArea()
    }
}
