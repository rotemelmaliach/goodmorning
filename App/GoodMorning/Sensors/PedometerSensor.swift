import CoreMotion
import GoodMorningCore

/// Counts steps since the routine step began. Pedometer updates lag by a few seconds,
/// which is fine for "did you actually get up and walk".
@MainActor
final class PedometerSensor: RoutineSensor {
    private let pedometer = CMPedometer()

    func start(emit: @escaping @MainActor (RoutineEvent) -> Void) {
        guard CMPedometer.isStepCountingAvailable() else { return }
        pedometer.startUpdates(from: Date()) { data, _ in
            guard let steps = data?.numberOfSteps.intValue else { return }
            Task { @MainActor in emit(.stepsWalked(steps)) }
        }
    }

    func stop() {
        pedometer.stopUpdates()
    }
}
