import SwiftUI

struct PotatoSlotKey: PreferenceKey {
    static let defaultValue: Anchor<CGRect>? = nil

    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = nextValue() ?? value
    }
}

struct PotatoSlot: View {
    var width: CGFloat = 220

    var body: some View {
        Color.clear
            .frame(width: width, height: width * 1.3)
            .anchorPreference(key: PotatoSlotKey.self, value: .bounds) { $0 }
    }
}

struct PotatoStage: View {
    let game: GameModel
    let slot: CGRect?
    let size: CGSize

    private let baseWidth: CGFloat = 240
    private let dockWidth: CGFloat = 54
    private let flight = Animation.spring(response: 0.6, dampingFraction: 0.74)

    @State private var lastFrame = CGRect.zero
    @State private var placed = false
    @State private var shattering = false
    @State private var shatterFrame = CGRect.zero
    @State private var gone = false

    private var frame: CGRect {
        if let slot { return slot }
        let height = dockWidth * 1.3
        return CGRect(x: size.width - dockWidth - 22, y: 64, width: dockWidth, height: height)
    }

    private var shake: Double {
        guard game.phase == .playing else { return 0 }
        switch game.step {
        case .holding: return min(1, 0.25 + game.potatoTime / 120)
        case .passing: return 0.9
        default: return 0.15
        }
    }

    private var spin: Double {
        guard game.phase == .playing else { return 0 }
        switch game.step {
        case .passing: return game.potatoTime * 220
        case .holding: return sin(game.potatoTime * 18) * 4 + Double(game.potatoDrag.width) * 0.08
        default: return 0
        }
    }

    var body: some View {
        ZStack {
            if !gone {
                PotatoBomb(width: baseWidth, lit: game.phase == .playing, shake: shake)
                    .keyframeAnimator(initialValue: CGFloat(1), trigger: game.potatoPokes) { content, squash in
                        content.scaleEffect(x: 2 - squash, y: squash, anchor: .bottom)
                    } keyframes: { _ in
                        KeyframeTrack {
                            SpringKeyframe(0.82, duration: 0.08)
                            SpringKeyframe(1.12, duration: 0.16)
                            SpringKeyframe(1, duration: 0.45, spring: .bouncy)
                        }
                    }
                    .rotationEffect(.degrees(spin))
                    .scaleEffect(frame.width / baseWidth)
                    .offset(game.potatoDrag)
                    .position(x: frame.midX, y: frame.midY)
                    .transition(.offset(y: -(size.height + 200)))
            }
            if shattering {
                PotatoShatter(width: baseWidth) {
                    shattering = false
                }
                .scaleEffect(shatterFrame.width / baseWidth)
                .position(x: shatterFrame.midX, y: shatterFrame.midY)
            }
        }
        .frame(width: size.width, height: size.height)
        .allowsHitTesting(false)
        .animation(placed ? flight : nil, value: frame)
        .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.8), value: game.potatoDrag)
        .onAppear {
            lastFrame = frame
            Task {
                try? await Task.sleep(for: .milliseconds(50))
                placed = true
            }
        }
        .onChange(of: frame) {
            if game.phase != .exploded { lastFrame = frame }
        }
        .onChange(of: game.phase) { old, new in
            if new == .exploded {
                shatterFrame = CGRect(
                    x: lastFrame.minX + game.potatoDrag.width,
                    y: lastFrame.minY + game.potatoDrag.height,
                    width: lastFrame.width,
                    height: lastFrame.height
                )
                game.potatoDrag = .zero
                gone = true
                shattering = true
            } else if old == .exploded {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.62)) { gone = false }
            }
        }
    }
}

extension View {
    func potatoStage(_ game: GameModel) -> some View {
        overlayPreferenceValue(PotatoSlotKey.self) { anchor in
            GeometryReader { geo in
                PotatoStage(game: game, slot: anchor.map { geo[$0] }, size: geo.size)
            }
        }
    }
}
