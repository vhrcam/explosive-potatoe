import SwiftUI

extension View {
    func staggerIn(_ shown: Bool, _ order: Int, from offset: CGFloat = 26) -> some View {
        self
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : offset)
            .scaleEffect(shown ? 1 : 0.96)
            .animation(.spring(duration: 0.6, bounce: 0.35).delay(Double(order) * 0.07), value: shown)
    }

    func jolt<T: Equatable>(_ trigger: T, strength: CGFloat = 1) -> some View {
        keyframeAnimator(initialValue: JoltValue(), trigger: trigger) { content, jolt in
            content
                .offset(x: jolt.x * strength, y: jolt.y * strength)
                .rotationEffect(.degrees(jolt.angle * strength))
        } keyframes: { _ in
            KeyframeTrack(\.x) {
                LinearKeyframe(18, duration: 0.05)
                LinearKeyframe(-15, duration: 0.05)
                LinearKeyframe(12, duration: 0.05)
                LinearKeyframe(-9, duration: 0.05)
                LinearKeyframe(6, duration: 0.05)
                LinearKeyframe(-3, duration: 0.05)
                LinearKeyframe(0, duration: 0.06)
            }
            KeyframeTrack(\.y) {
                LinearKeyframe(-9, duration: 0.05)
                LinearKeyframe(7, duration: 0.05)
                LinearKeyframe(-5, duration: 0.05)
                LinearKeyframe(3, duration: 0.05)
                LinearKeyframe(0, duration: 0.06)
            }
            KeyframeTrack(\.angle) {
                LinearKeyframe(-2.5, duration: 0.06)
                LinearKeyframe(2, duration: 0.06)
                LinearKeyframe(-1, duration: 0.06)
                LinearKeyframe(0, duration: 0.06)
            }
        }
    }
}

nonisolated struct JoltValue {
    var x: CGFloat = 0
    var y: CGFloat = 0
    var angle: Double = 0
}

struct CountUpText: View {
    let value: Int
    var duration = 0.9
    @State private var shown = 0

    var body: some View {
        Text("\(shown)")
            .monospacedDigit()
            .task(id: value) {
                let start = shown
                let steps = max(Int(duration * 40), 1)
                for step in 1...steps {
                    try? await Task.sleep(for: .seconds(duration / Double(steps)))
                    guard !Task.isCancelled else { return }
                    let t = Double(step) / Double(steps)
                    shown = start + Int((Double(value - start) * (1 - pow(1 - t, 3))).rounded())
                }
            }
    }
}
