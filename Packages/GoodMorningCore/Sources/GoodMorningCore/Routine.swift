import Foundation

public enum Exercise: String, Codable, Sendable, CaseIterable {
    case jumpingJack
    case squat

    public var title: String {
        switch self {
        case .jumpingJack: "Jumping jacks"
        case .squat: "Squats"
        }
    }

    /// A different exercise each day, so the alarm can't be silenced on autopilot.
    public static func rotating(on day: Date, calendar: Calendar = .current) -> Exercise {
        let index = calendar.ordinality(of: .day, in: .era, for: day) ?? 0
        return allCases[index % allCases.count]
    }
}

/// What has to happen for a step to count as done, and therefore which sensor verifies it.
public enum StepGoal: Codable, Sendable, Equatable {
    /// Pedometer: walk this many steps (proves you left the bed).
    case walk(steps: Int)
    /// Front camera body pose: do this many reps.
    case reps(exercise: Exercise, count: Int)
    /// Apple Watch: keep heart rate at or above a threshold for a while.
    case heartRate(atLeastBPM: Double, holdSeconds: TimeInterval)
    /// Camera: scan a code stuck somewhere away from the bed (e.g. bathroom mirror).
    case scanCode(payload: String)
    /// Front camera body pose: accumulate this much time actually doing the stretch.
    case stretch(Stretch, seconds: TimeInterval)
    /// Unverified wait (e.g. drink water).
    case timer(seconds: TimeInterval)
    /// Manual tap.
    case confirm
}

public struct RoutineStep: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var title: String
    public var instruction: String
    public var goal: StepGoal
    /// Past this many seconds the alarm sound escalates. The step still has to be completed.
    public var timeLimit: TimeInterval?
    /// Whether the alarm keeps ringing while this step is in progress.
    public var alarmSounding: Bool

    public init(
        id: String,
        title: String,
        instruction: String,
        goal: StepGoal,
        timeLimit: TimeInterval? = nil,
        alarmSounding: Bool = false
    ) {
        self.id = id
        self.title = title
        self.instruction = instruction
        self.goal = goal
        self.timeLimit = timeLimit
        self.alarmSounding = alarmSounding
    }
}

public struct Routine: Codable, Sendable, Equatable {
    public var name: String
    public var steps: [RoutineStep]

    public init(name: String, steps: [RoutineStep]) {
        self.name = name
        self.steps = steps
    }

    /// The default sequence from docs/wake-protocol.md (section 2), with one change the user asked for:
    /// the alarm never stops on its own. It rings from the first step until the camera has counted
    /// `wakeReps` of `wakeExercise`. There is no fallback and no other way to silence it.
    ///
    /// After that single set of reps the routine goes straight into the stretch sequence.
    /// Steps whose sensor isn't built yet (lights, sink anchor) use a tap for now.
    public static func researchedDefault(
        wakeExercise: Exercise,
        wakeReps: Int = 20,
        stretchSeconds: TimeInterval = 15
    ) -> Routine {
        var steps = [
            RoutineStep(
                id: "sit",
                title: "Sit up",
                instruction: "Feet on the floor. Stay seated for 10 seconds before you stand.",
                goal: .timer(seconds: 10),
                alarmSounding: true
            ),
            RoutineStep(
                id: "lights",
                title: "Lights on",
                instruction: "Turn on the lights or open the curtains, then tap.",
                goal: .confirm,
                timeLimit: 30,
                alarmSounding: true
            ),
            RoutineStep(
                id: "wake-reps",
                title: "\(wakeReps) \(wakeExercise.title.lowercased()) to stop the alarm",
                instruction: "Prop the phone up and take a few steps back. Head to hips in view is enough.",
                goal: .reps(exercise: wakeExercise, count: wakeReps),
                timeLimit: 120,
                alarmSounding: true
            ),
        ]
        steps += Stretch.allCases.map {
            RoutineStep(
                id: "stretch-\($0.rawValue)",
                title: $0.title,
                instruction: $0.instruction,
                goal: .stretch($0, seconds: stretchSeconds),
                timeLimit: stretchSeconds * 4
            )
        }
        steps += [
            RoutineStep(
                id: "face",
                title: "Cold water on your face",
                instruction: "Go to the sink, splash three times, then tap.",
                goal: .confirm,
                timeLimit: 120
            ),
            RoutineStep(
                id: "water",
                title: "Drink a glass of water",
                instruction: "About 300 ml. Tap when you're done.",
                goal: .confirm
            ),
        ]
        return Routine(name: "Default", steps: steps)
    }
}
