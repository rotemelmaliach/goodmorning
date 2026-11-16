import Foundation
import GoodMorningCore
import Observation

/// Something that watches the real world for one step and reports events.
@MainActor
protocol RoutineSensor: AnyObject {
    func start(emit: @escaping @MainActor (RoutineEvent) -> Void)
    func stop()
}

/// Glue between the pure `RoutineEngine` and the device: runs the clock, starts the right
/// sensor for each step, and turns engine effects into sound, alarms and saved history.
@MainActor
@Observable
final class RoutineSession {
    static let shared = RoutineSession()

    private(set) var engine: RoutineEngine?
    /// Non-nil while a camera step is running, so the UI can show the preview.
    private(set) var camera: PoseCameraSensor?

    private var sensor: RoutineSensor?
    private var ticker: Timer?
    private let sound = AlarmSoundPlayer()
    private let alarms = AlarmService()

    var isActive: Bool {
        if case .running = engine?.phase { return true }
        return false
    }

    /// Entry point from the alarm's stop intent, and from the "test now" button.
    func begin() {
        guard !isActive else { return }
        var engine = RoutineEngine(routine: Store.routine)
        let effects = engine.start(at: .now)
        self.engine = engine
        apply(effects)
        ticker = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.advance { $0.tick(at: .now) } }
        }
    }

    func send(_ event: RoutineEvent) {
        advance { $0.handle(event, at: .now) }
    }

    func rearmAlarms(completedToday: Bool = false) async {
        do {
            guard try await alarms.requestAuthorization() else { return }
            try await alarms.rearm(schedule: Store.schedule, completedDay: completedToday ? .now : nil)
        } catch {
            print("Alarm scheduling failed: \(error)")
        }
    }

    // MARK: - Private

    private func advance(_ step: (inout RoutineEngine) -> [RoutineEffect]) {
        guard var engine else { return }
        let effects = step(&engine)
        self.engine = engine
        apply(effects)
    }

    private func apply(_ effects: [RoutineEffect]) {
        for effect in effects {
            switch effect {
            case .stepBegan(let index):
                guard let goal = engine?.routine.steps[index].goal else { continue }
                startSensor(for: goal)
            case .stepFinished:
                sensor?.stop()
                sensor = nil
                camera = nil
            case .alarmSound(let level):
                sound.set(level)
            case .routineFinished(let summary):
                ticker?.invalidate()
                ticker = nil
                Store.record(summary)
                WatchLink.shared.endWorkout()
                Task { await rearmAlarms(completedToday: true) }
            }
        }
    }

    private func startSensor(for goal: StepGoal) {
        switch goal {
        case .walk:
            sensor = PedometerSensor()
        case .reps(let exercise, _):
            sensor = makeCamera(.reps(exercise))
        case .stretch(let stretch, _):
            sensor = makeCamera(.stretch(stretch))
        case .heartRate:
            sensor = WatchHeartRateSensor()
        case .scanCode, .timer, .confirm:
            sensor = nil  // scanCode: sensor not built yet; timer/confirm need none.
        }
        sensor?.start { [weak self] event in self?.send(event) }
    }

    private func makeCamera(_ mode: PoseCameraSensor.Mode) -> PoseCameraSensor {
        let camera = PoseCameraSensor(mode: mode)
        self.camera = camera
        return camera
    }
}

/// Settings and history. UserDefaults is enough for a single-user app.
enum Store {
    private static let defaults = UserDefaults.standard

    static var schedule: WakeSchedule {
        get { load("schedule") ?? WakeSchedule() }
        set { save(newValue, "schedule") }
    }

    /// The exercise that silences the alarm. nil means a different one each day.
    static var wakeExercise: Exercise? {
        get { load("wakeExercise") }
        set { save(newValue, "wakeExercise") }
    }

    static var routine: Routine {
        .researchedDefault(wakeExercise: wakeExercise ?? .rotating(on: .now))
    }

    static var history: [RoutineSummary] {
        get { load("history") ?? [] }
        set { save(newValue, "history") }
    }

    static func record(_ summary: RoutineSummary) {
        history.append(summary)
    }

    static var streak: Int {
        Streak.current(completedDays: history.map(\.finishedAt), weekdays: schedule.weekdays, skippedDays: schedule.skippedDays, today: .now)
    }

    private static func load<T: Decodable>(_ key: String) -> T? {
        defaults.data(forKey: key).flatMap { try? JSONDecoder().decode(T.self, from: $0) }
    }

    private static func save<T: Encodable>(_ value: T, _ key: String) {
        defaults.set(try? JSONEncoder().encode(value), forKey: key)
    }
}
