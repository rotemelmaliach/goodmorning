import AVFoundation
import GoodMorningCore
import Observation

/// In-app alarm: loops the chosen calming sound while a step is unfinished. It starts barely
/// audible and swells (`AlarmVolumeRamp`); with the `audio` background mode it survives the
/// screen locking.
@MainActor
final class AlarmSoundPlayer {
    var ramp = AlarmVolumeRamp()

    private var player: AVAudioPlayer?
    private var level: AlarmSoundLevel = .off
    private var startedAt: Date?
    private var timer: Timer?

    func set(_ level: AlarmSoundLevel) {
        self.level = level
        guard level != .off else {
            stop()
            return
        }
        if player == nil { start(Store.alarmSound) }
        updateVolume(fade: level == .escalated ? 1.0 : 0)
    }

    private func start(_ sound: AlarmSound) {
        guard let player = Sounds.player(for: sound.loopFile) else { return }
        player.numberOfLoops = -1
        player.volume = Float(ramp.startVolume)
        player.play()
        self.player = player
        startedAt = .now
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.updateVolume(fade: 1) }
        }
    }

    private func stop() {
        timer?.invalidate()
        timer = nil
        player?.setVolume(0, fadeDuration: 0.6)
        let fading = player
        player = nil
        startedAt = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { fading?.stop() }
    }

    private func updateVolume(fade: TimeInterval) {
        guard let player, let startedAt else { return }
        let volume = Float(ramp.volume(elapsed: Date.now.timeIntervalSince(startedAt), level: level))
        player.setVolume(volume, fadeDuration: fade)
    }
}

/// Plays a few seconds of a sound from the picker on the home screen.
@MainActor
@Observable
final class SoundPreview {
    private(set) var playing: AlarmSound?
    @ObservationIgnored private var player: AVAudioPlayer?
    @ObservationIgnored private var stopTask: Task<Void, Never>?

    func toggle(_ sound: AlarmSound) {
        let wasPlaying = playing == sound
        stop()
        guard !wasPlaying, let player = Sounds.player(for: sound.loopFile) else { return }
        player.volume = 0
        player.play()
        player.setVolume(0.7, fadeDuration: 1.5)
        self.player = player
        playing = sound
        stopTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(8))
            if !Task.isCancelled { self?.stop() }
        }
    }

    func stop() {
        stopTask?.cancel()
        stopTask = nil
        player?.stop()
        player = nil
        playing = nil
    }
}

enum Sounds {
    /// A ready-to-play player for a bundled sound file, with the audio session set to play
    /// even when the phone's silent switch is on.
    @MainActor
    static func player(for fileName: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: nil) else {
            print("Missing sound file \(fileName)")
            return nil
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            return player
        } catch {
            print("Alarm sound failed: \(error)")
            return nil
        }
    }
}
