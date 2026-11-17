import Foundation

/// The calming alarm sounds that ship with the app. Each one is a pair of audio files generated
/// by `tools/make_sounds.py`: `<fileStem>.wav` loops inside the app, and `<fileStem>-alarm.wav`
/// (with a slow fade-in baked in) is what the system alarm plays before the app is open.
public enum AlarmSound: String, Codable, Sendable, CaseIterable, Identifiable {
    case dawnChimes, singingBowl, oceanWaves, softHarp, morningBirds

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .dawnChimes: "Dawn chimes"
        case .singingBowl: "Singing bowl"
        case .oceanWaves: "Ocean waves"
        case .softHarp: "Soft harp"
        case .morningBirds: "Morning birds"
        }
    }

    public var detail: String {
        switch self {
        case .dawnChimes: "Slow, bright bells"
        case .singingBowl: "One long, warm tone"
        case .oceanWaves: "Waves rolling in"
        case .softHarp: "A gentle rising melody"
        case .morningBirds: "Birdsong over a quiet pad"
        }
    }

    public var fileStem: String {
        switch self {
        case .dawnChimes: "dawn-chimes"
        case .singingBowl: "singing-bowl"
        case .oceanWaves: "ocean-waves"
        case .softHarp: "soft-harp"
        case .morningBirds: "morning-birds"
        }
    }

    public var loopFile: String { fileStem + ".wav" }
    public var alarmFile: String { fileStem + "-alarm.wav" }
}

/// How loud the in-app alarm is over time: it starts barely audible and swells, so waking up
/// is gradual. Running past a step's time limit jumps straight to full volume.
public struct AlarmVolumeRamp: Sendable, Equatable {
    public var startVolume: Double
    public var rampSeconds: TimeInterval

    public init(startVolume: Double = 0.08, rampSeconds: TimeInterval = 75) {
        self.startVolume = startVolume
        self.rampSeconds = rampSeconds
    }

    /// Volume 0...1 for an alarm that has been sounding for `elapsed` seconds.
    public func volume(elapsed: TimeInterval, level: AlarmSoundLevel) -> Double {
        switch level {
        case .off: return 0
        case .escalated: return 1
        case .normal:
            guard rampSeconds > 0 else { return 1 }
            let t = min(max(elapsed / rampSeconds, 0), 1)
            // Ease-in: the first third of the ramp stays quiet.
            return startVolume + (1 - startVolume) * t * t
        }
    }
}
