import Foundation

/// Input from sensors and the UI.
public enum RoutineEvent: Sendable, Equatable {
    /// Cumulative steps since the current routine step began.
    case stepsWalked(Int)
    case repCounted(Exercise)
    /// Seconds of valid stretching seen since the last event.
    case stretchHeld(Stretch, seconds: TimeInterval)
    case heartRate(bpm: Double)
    case codeScanned(String)
    case confirmed
}

public enum AlarmSoundLevel: String, Codable, Sendable {
    case off, normal, escalated
}

/// Output the app layer must act on (start a sensor, change the sound, save history).
public enum RoutineEffect: Sendable, Equatable {
    case stepBegan(index: Int)
    case stepFinished(index: Int)
    case alarmSound(AlarmSoundLevel)
    case routineFinished(RoutineSummary)
}

public struct StepRecord: Codable, Sendable, Equatable {
    public var stepID: String
    public var duration: TimeInterval
    public var overTimeLimit: Bool
}

public struct RoutineSummary: Codable, Sendable, Equatable {
    public var startedAt: Date
    public var finishedAt: Date
    public var steps: [StepRecord]

    public var totalDuration: TimeInterval { finishedAt.timeIntervalSince(startedAt) }
}

/// The wake-up sequence as a state machine. It has no clock and no sensors of its own:
/// the caller passes the time in and feeds it events, which keeps it testable anywhere.
/// There is deliberately no skip or abort: hard mode means the only way out is through.
public struct RoutineEngine: Sendable {
    public enum Phase: Sendable, Equatable {
        case idle
        case running(stepIndex: Int)
        case finished(RoutineSummary)
    }

    public let routine: Routine
    public private(set) var phase: Phase = .idle
    /// Progress of the current step, 0...1.
    public private(set) var progress: Double = 0
    /// Steps walked or reps done in the current step.
    public private(set) var count: Int = 0

    private var startedAt: Date?
    private var stepStartedAt: Date?
    private var escalated = false
    private var heartRateHeldSince: Date?
    private var stretchHeld: TimeInterval = 0
    private var records: [StepRecord] = []

    public init(routine: Routine) {
        self.routine = routine
    }

    public var currentStep: RoutineStep? {
        guard case .running(let index) = phase else { return nil }
        return routine.steps[index]
    }

    public mutating func start(at now: Date) -> [RoutineEffect] {
        guard phase == .idle else { return [] }
        startedAt = now
        return begin(0, at: now)
    }

    public mutating func handle(_ event: RoutineEvent, at now: Date) -> [RoutineEffect] {
        guard case .running(let index) = phase else { return [] }
        var done = false

        switch (routine.steps[index].goal, event) {
        case (.walk(let target), .stepsWalked(let total)):
            count = max(count, total)
            progress = fraction(count, of: target)
            done = count >= target
        case (.reps(let exercise, let target), .repCounted(let counted)) where counted == exercise:
            count += 1
            progress = fraction(count, of: target)
            done = count >= target
        case (.stretch(let stretch, let target), .stretchHeld(let held, let seconds)) where held == stretch:
            stretchHeld += seconds
            progress = target > 0 ? min(1, stretchHeld / target) : 1
            done = stretchHeld >= target
        case (.heartRate(let threshold, let hold), .heartRate(let bpm)):
            if bpm >= threshold {
                heartRateHeldSince = heartRateHeldSince ?? now
            } else {
                heartRateHeldSince = nil
            }
            done = updateHeartRateHold(hold, at: now)
        case (.scanCode(let payload), .codeScanned(let scanned)):
            done = scanned == payload
        case (.confirm, .confirmed):
            done = true
        default:
            break
        }

        return done ? finishStep(index, at: now) : []
    }

    /// Call a few times per second while running. Drives timers and time-limit escalation.
    public mutating func tick(at now: Date) -> [RoutineEffect] {
        guard case .running(let index) = phase, let began = stepStartedAt else { return [] }
        let step = routine.steps[index]
        let elapsed = now.timeIntervalSince(began)

        switch step.goal {
        case .timer(let seconds):
            progress = seconds > 0 ? min(1, elapsed / seconds) : 1
            if elapsed >= seconds { return finishStep(index, at: now) }
        case .heartRate(_, let hold):
            if updateHeartRateHold(hold, at: now) { return finishStep(index, at: now) }
        default:
            break
        }

        if let limit = step.timeLimit, elapsed > limit, !escalated {
            escalated = true
            return [.alarmSound(.escalated)]
        }
        return []
    }

    // MARK: - Private

    private mutating func begin(_ index: Int, at now: Date) -> [RoutineEffect] {
        guard index < routine.steps.count else {
            let summary = RoutineSummary(startedAt: startedAt ?? now, finishedAt: now, steps: records)
            phase = .finished(summary)
            return [.alarmSound(.off), .routineFinished(summary)]
        }
        phase = .running(stepIndex: index)
        stepStartedAt = now
        progress = 0
        count = 0
        escalated = false
        heartRateHeldSince = nil
        stretchHeld = 0
        return [
            .stepBegan(index: index),
            .alarmSound(routine.steps[index].alarmSounding ? .normal : .off),
        ]
    }

    private mutating func finishStep(_ index: Int, at now: Date) -> [RoutineEffect] {
        records.append(
            StepRecord(
                stepID: routine.steps[index].id,
                duration: now.timeIntervalSince(stepStartedAt ?? now),
                overTimeLimit: escalated
            )
        )
        return [.stepFinished(index: index)] + begin(index + 1, at: now)
    }

    private mutating func updateHeartRateHold(_ hold: TimeInterval, at now: Date) -> Bool {
        guard let since = heartRateHeldSince else {
            progress = 0
            return false
        }
        let held = now.timeIntervalSince(since)
        progress = hold > 0 ? min(1, held / hold) : 1
        return held >= hold
    }

    private func fraction(_ value: Int, of target: Int) -> Double {
        target > 0 ? min(1, Double(value) / Double(target)) : 1
    }
}
