import HealthKit
import SwiftUI
import WatchConnectivity
import WatchKit

@main
struct GoodMorningWatchApp: App {
    @WKApplicationDelegateAdaptor private var delegate: WatchDelegate

    var body: some Scene {
        WindowGroup {
            VStack {
                Image(systemName: "sunrise.fill").font(.largeTitle).foregroundStyle(.orange)
                Text("Good Morning")
                Text("Follow the routine on your iPhone").font(.footnote).multilineTextAlignment(.center)
            }
        }
    }
}

/// Watch side: when the phone starts the routine, run a workout session so heart rate
/// keeps streaming, and forward each sample to the phone.
final class WatchDelegate: NSObject, WKApplicationDelegate, WCSessionDelegate, HKLiveWorkoutBuilderDelegate {
    private let healthStore = HKHealthStore()
    private var workout: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    func applicationDidFinishLaunching() {
        WCSession.default.delegate = self
        WCSession.default.activate()
        let heartRate = HKQuantityType(.heartRate)
        healthStore.requestAuthorization(toShare: [HKObjectType.workoutType()], read: [heartRate]) { _, _ in }
    }

    /// Called when the iPhone runs `HKHealthStore.startWatchApp(with:)`.
    func handle(_ workoutConfiguration: HKWorkoutConfiguration) {
        guard workout == nil,
              let session = try? HKWorkoutSession(healthStore: healthStore, configuration: workoutConfiguration)
        else { return }
        let builder = session.associatedWorkoutBuilder()
        builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: workoutConfiguration)
        builder.delegate = self
        session.startActivity(with: .now)
        builder.beginCollection(withStart: .now) { _, _ in }
        workout = session
        self.builder = builder
        WKInterfaceDevice.current().play(.start)
    }

    private func endWorkout() {
        workout?.end()
        builder?.endCollection(withEnd: .now) { [builder] _, _ in
            builder?.finishWorkout { _, _ in }
        }
        workout = nil
        builder = nil
        WKInterfaceDevice.current().play(.success)
    }

    // MARK: - HKLiveWorkoutBuilderDelegate

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        let heartRate = HKQuantityType(.heartRate)
        guard collectedTypes.contains(heartRate),
              let quantity = workoutBuilder.statistics(for: heartRate)?.mostRecentQuantity()
        else { return }
        let bpm = quantity.doubleValue(for: .count().unitDivided(by: .minute()))
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(["hr": bpm], replyHandler: nil)
        }
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if message["command"] as? String == "end" {
            DispatchQueue.main.async { self.endWorkout() }
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {}
}
