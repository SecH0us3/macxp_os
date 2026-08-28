import Foundation
import Combine
import AVFoundation

public class SoundManager: ObservableObject {
    public static let shared = SoundManager()

    @Published public var volume: Float = 0.8
    @Published public var isMuted: Bool = false
    @Published public var isEnabled: Bool = true
    @Published public var lastPlayedSound: XPSound? = nil
    @Published public var playCount: Int = 0

    private var audioDataCache: [XPSound: Data] = [:]
    private var activePlayers: [AVAudioPlayer] = []
    private let lock = NSLock()

    public init(volume: Float = 0.8, isMuted: Bool = false, isEnabled: Bool = true) {
        self.volume = max(0.0, min(1.0, volume))
        self.isMuted = isMuted
        self.isEnabled = isEnabled
    }

    public func setVolume(_ value: Float) {
        let clamped = max(0.0, min(1.0, value))
        self.volume = clamped
        if clamped > 0.0 && isMuted {
            self.isMuted = false
        }
        lock.lock()
        for player in activePlayers {
            player.volume = isMuted ? 0.0 : clamped
        }
        lock.unlock()
    }

    public func setMuted(_ muted: Bool) {
        self.isMuted = muted
        lock.lock()
        for player in activePlayers {
            player.volume = muted ? 0.0 : volume
        }
        lock.unlock()
    }

    public func toggleMute() {
        setMuted(!isMuted)
    }

    public func play(_ sound: XPSound) {
        lastPlayedSound = sound
        playCount += 1

        guard isEnabled else { return }

        let wavData: Data
        lock.lock()
        if let cached = audioDataCache[sound] {
            wavData = cached
        } else {
            let generated = XPSoundSynthesizer.generateWAV(for: sound)
            audioDataCache[sound] = generated
            wavData = generated
        }
        lock.unlock()

        do {
            let player = try AVAudioPlayer(data: wavData)
            player.volume = isMuted ? 0.0 : volume
            player.prepareToPlay()
            if !isMuted && volume > 0 {
                player.play()
            }
            lock.lock()
            activePlayers.append(player)
            // Clean up stopped players
            activePlayers.removeAll { !$0.isPlaying }
            lock.unlock()
        } catch {
            // Audio output device might not be available in headless test runners
            // State is still properly updated
        }
    }

    public func stopAll() {
        lock.lock()
        for player in activePlayers {
            player.stop()
        }
        activePlayers.removeAll()
        lock.unlock()
    }
}
