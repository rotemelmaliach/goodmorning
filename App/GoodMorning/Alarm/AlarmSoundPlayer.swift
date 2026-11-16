import AVFoundation
import GoodMorningCore

/// In-app alarm tone that keeps going while a step is unfinished. It synthesizes beeps,
/// so no audio asset is needed; with the `audio` background mode it survives the screen locking.
final class AlarmSoundPlayer {
    private let engine = AVAudioEngine()
    private let sampleRate = 44_100.0
    private var sample = 0.0
    private var level: AlarmSoundLevel = .off
    private var attached = false

    func set(_ level: AlarmSoundLevel) {
        self.level = level
        if level == .off {
            engine.stop()
            return
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
            attachIfNeeded()
            if !engine.isRunning { try engine.start() }
        } catch {
            print("Alarm sound failed: \(error)")
        }
    }

    private func attachIfNeeded() {
        guard !attached else { return }
        attached = true
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let node = AVAudioSourceNode { [unowned self] _, _, frameCount, audioBufferList in
            let escalated = self.level == .escalated
            let frequency = escalated ? 1320.0 : 880.0
            let period = escalated ? 0.2 : 0.5
            let gain: Float = escalated ? 1.0 : 0.6
            let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0..<Int(frameCount) {
                let time = self.sample / self.sampleRate
                let beeping = time.truncatingRemainder(dividingBy: period) < period / 2
                let value = beeping ? Float(sin(2 * .pi * frequency * time)) * gain : 0
                self.sample += 1
                for buffer in buffers {
                    buffer.mData?.assumingMemoryBound(to: Float.self)[frame] = value
                }
            }
            return noErr
        }
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
    }
}
