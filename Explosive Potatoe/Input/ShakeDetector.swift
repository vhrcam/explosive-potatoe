import SwiftUI
import UIKit
import Combine
import CoreMotion

extension View {
    func onShake(enabled: Bool = true, perform action: @escaping () -> Void) -> some View {
        modifier(ShakeModifier(enabled: enabled, action: action))
    }
}

extension Notification.Name {
    static let deviceShook = Notification.Name("deviceShook")
}

final class ShakeDetector {
    static let shared = ShakeDetector()

    private let motion = CMMotionManager()
    private var listeners: Set<UUID> = []
    private var lastShake = Date.distantPast
    private let threshold = 1.6
    private let debounce = 0.3

    var usesMotion: Bool { motion.isDeviceMotionAvailable }

    func listen(_ id: UUID, _ on: Bool) {
        if on { listeners.insert(id) } else { listeners.remove(id) }

        if listeners.isEmpty {
            motion.stopDeviceMotionUpdates()
        } else if usesMotion && !motion.isDeviceMotionActive {
            motion.deviceMotionUpdateInterval = 1.0 / 60
            motion.startDeviceMotionUpdates(to: .main) { data, _ in
                guard let a = data?.userAcceleration else { return }
                let g = (a.x * a.x + a.y * a.y + a.z * a.z).squareRoot()
                MainActor.assumeIsolated { ShakeDetector.shared.sample(g) }
            }
        }
    }

    func shake() {
        let now = Date()
        guard now.timeIntervalSince(lastShake) > debounce else { return }
        lastShake = now
        NotificationCenter.default.post(name: .deviceShook, object: nil)
    }

    private func sample(_ g: Double) {
        if g > threshold { shake() }
    }
}

// Simulator fallback (Device > Shake, ⌃⌘Z). On a real phone CoreMotion handles it.
extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake && !ShakeDetector.shared.usesMotion {
            ShakeDetector.shared.shake()
        }
        super.motionEnded(motion, with: event)
    }
}

private struct ShakeModifier: ViewModifier {
    let enabled: Bool
    let action: () -> Void

    @State private var id = UUID()
    @State private var onScreen = false

    func body(content: Content) -> some View {
        content
            .onAppear {
                onScreen = true
                ShakeDetector.shared.listen(id, enabled)
            }
            .onDisappear {
                onScreen = false
                ShakeDetector.shared.listen(id, false)
            }
            .onChange(of: enabled) { _, on in
                ShakeDetector.shared.listen(id, on && onScreen)
            }
            .onReceive(NotificationCenter.default.publisher(for: .deviceShook)) { _ in
                if enabled && onScreen { action() }
            }
    }
}
