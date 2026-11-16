import GoodMorningCore
import HealthKit
import WatchConnectivity

/// Phone side of the Apple Watch connection: launches a workout on the watch and
/// receives live heart rate from it.
final class WatchLink: NSObject, WCSessionDelegate {
    static let shared = WatchLink()

    var onHeartRate: (@MainActor (Double) -> Void)?
    private let healthStore = HKHealthStore()

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// Wakes the watch app and starts a workout session there, which is what lets the watch
    /// keep sampling heart rate with its screen off.
    func startWorkout() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .functionalStrengthTraining
        configuration.locationType = .indoor
        healthStore.startWatchApp(with: configuration) { _, error in
            if let error { print("Could not start watch workout: \(error)") }
        }
    }

    func endWorkout() {
        guard WCSession.default.activationState == .activated, WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(["command": "end"], replyHandler: nil)
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let bpm = message["hr"] as? Double else { return }
        Task { @MainActor in self.onHeartRate?(bpm) }
    }

    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
}

@MainActor
final class WatchHeartRateSensor: RoutineSensor {
    func start(emit: @escaping @MainActor (RoutineEvent) -> Void) {
        WatchLink.shared.onHeartRate = { emit(.heartRate(bpm: $0)) }
        WatchLink.shared.startWorkout()
    }

    func stop() {
        WatchLink.shared.onHeartRate = nil
    }
}
