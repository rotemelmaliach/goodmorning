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
    /// Set when a routine has just been completed, until the user dismisses the summary.
    var finished: RoutineSummary?

    /// The user is asked to step back once per routine, at its first camera step.
    private var framedThisRoutine = false
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
        finished = nil
        framedThisRoutine = false
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
                // A camera stays on between consecutive camera steps; see startSensor.
                if sensor !== camera { sensor?.stop() }
                sensor = nil
            case .alarmSound(let level):
                sound.set(level)
            case .routineFinished(let summary):
                ticker?.invalidate()
                ticker = nil
                stopCamera()
                Store.record(summary)
                finished = summary
                WatchLink.shared.endWorkout()
                Task { await rearmAlarms(completedToday: true) }
            }
        }
    }

    private func startSensor(for goal: StepGoal) {
        switch goal {
        case .reps(let exercise, _):
            useCamera(.reps(exercise))
            return
        case .walk:
            sensor = PedometerSensor()
        case .heartRate:
            sensor = WatchHeartRateSensor()
        case .scanCode, .timer, .confirm, .stretch:
            // scanCode: sensor not built yet. Stretches are guided by photos, not the camera.
            sensor = nil
        }
        stopCamera()
        sensor?.start { [weak self] event in self?.send(event) }
    }

    /// Reuses the running camera when the previous step used it too, so the preview
    /// doesn't blink between stretches.
    private func useCamera(_ mode: PoseCameraSensor.Mode) {
        if let camera {
            camera.switchTo(mode)
            sensor = camera
            return
        }
        // Push-ups happen close to the phone on the floor, so they don't ask for a step back.
        var needsStepBack = true
        if case .reps(let exercise) = mode { needsStepBack = exercise.needsStepBack }
        let camera = PoseCameraSensor(mode: mode, requireFraming: needsStepBack && !framedThisRoutine)
        if needsStepBack { framedThisRoutine = true }
        self.camera = camera
        sensor = camera
        camera.start { [weak self] event in self?.send(event) }
    }

    private func stopCamera() {
        camera?.stop()
        camera = nil
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

    /// The calming sound used for the alarm, in the app and for the system alarm.
    static var alarmSound: AlarmSound {
        get { load("alarmSound") ?? .dawnChimes }
        set { save(newValue, "alarmSound") }
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
