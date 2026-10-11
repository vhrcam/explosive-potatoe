import AVFoundation
import SwiftUI
import UIKit

nonisolated enum SFX {
    enum Sound: String, CaseIterable {
        case tap, pop, whoosh, grab, boom, success, fail, tick, flip, fuseLit, win
        case swish, splash, snip, zap
    }

    private static let mutedKey = "sfxMuted"
    private static let poolSize = 3
    private static let sizzleVolume: Float = 0.3
    private static let queue = DispatchQueue(label: "sfx", qos: .userInitiated)

    nonisolated(unsafe) private static var pools: [Sound: [AVAudioPlayer]] = [:]
    nonisolated(unsafe) private static var nextIndex: [Sound: Int] = [:]
    nonisolated(unsafe) private static var sizzle: AVAudioPlayer?
    nonisolated(unsafe) private static var warmUp: AVAudioPlayer?
    nonisolated(unsafe) private static var isLoaded = false

    static var isMuted: Bool {
        get { UserDefaults.standard.bool(forKey: mutedKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: mutedKey)
            if newValue { stopSizzle() }
        }
    }

    static func preload() {
        queue.async { load() }
    }

    static func play(_ sound: Sound, pitch: Float = 1) {
        guard !isMuted else { return }
        queue.async {
            load()
            guard let pool = pools[sound], !pool.isEmpty else { return }
            let index = nextIndex[sound, default: 0]
            nextIndex[sound] = (index + 1) % pool.count
            let player = pool[index]
            player.rate = min(max(pitch, 0.5), 2)
            player.currentTime = 0
            player.play()
        }
    }

    static func startSizzle() {
        guard !isMuted else { return }
        queue.async {
            load()
            guard let sizzle, !sizzle.isPlaying else { return }
            sizzle.currentTime = 0
            sizzle.play()
        }
    }

    static func stopSizzle() {
        queue.async { sizzle?.stop() }
    }

    private static func load() {
        guard !isLoaded else { return }
        isLoaded = true
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
        for sound in Sound.allCases {
            pools[sound] = (0..<poolSize).compactMap { _ in player(sound.rawValue) }
        }
        sizzle = player("sizzle")
        sizzle?.numberOfLoops = -1
        sizzle?.volume = sizzleVolume
        warmUp = player("tap")
        warmUp?.volume = 0
        warmUp?.play()
    }

    private static func player(_ name: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav"),
              let player = try? AVAudioPlayer(contentsOf: url) else { return nil }
        player.enableRate = true
        player.prepareToPlay()
        return player
    }
}

enum Haptics {
    private static let heartbeatGap = 0.14
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let medium = UIImpactFeedbackGenerator(style: .medium)
    private static let strong = UIImpactFeedbackGenerator(style: .heavy)
    private static let notice = UINotificationFeedbackGenerator()

    static func prepare() {
        light.prepare()
        strong.prepare()
        notice.prepare()
    }

    static func tap() {
        light.impactOccurred()
        light.prepare()
    }

    static func success() {
        notice.notificationOccurred(.success)
        notice.prepare()
    }

    static func fail() {
        notice.notificationOccurred(.error)
        notice.prepare()
    }

    static func heavy() {
        strong.impactOccurred()
        strong.prepare()
    }

    static func heartbeat() {
        strong.impactOccurred(intensity: 0.9)
        medium.prepare()
        Task {
            try? await Task.sleep(for: .seconds(heartbeatGap))
            medium.impactOccurred(intensity: 0.6)
            strong.prepare()
        }
    }
}
