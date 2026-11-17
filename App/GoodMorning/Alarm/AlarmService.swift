import ActivityKit
import AlarmKit
import AppIntents
import GoodMorningCore
import SwiftUI

// NOTE: written against the iOS 26 AlarmKit API without a compiler at hand (authored on Windows).
// Expect small signature fixes on the first CI build.

struct WakeMetadata: AlarmMetadata {}

/// Runs when an alarm is stopped. Opens the app and starts the routine, so silencing
/// the system alarm is the beginning of the sequence rather than the end of it.
struct StartRoutineIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Start morning routine"
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        await RoutineSession.shared.begin()
        return .result()
    }
}

@MainActor
final class AlarmService {
    private let manager = AlarmManager.shared

    func requestAuthorization() async throws -> Bool {
        try await manager.requestAuthorization() == .authorized
    }

    /// Replaces every scheduled alarm with a fresh plan: main alarm plus backups for the next days.
    /// Backups for a day only disappear when this is called with that day as `completedDay`.
    func rearm(schedule: WakeSchedule, completedDay: Date?) async throws {
        for alarm in try manager.alarms {
            try? manager.cancel(id: alarm.id)
        }
        for planned in AlarmPlanner.plan(schedule: schedule, from: .now, completedDay: completedDay) {
            let title: LocalizedStringResource = planned.isBackup ? "Finish your routine" : "Good morning"
            let alert = AlarmPresentation.Alert(
                title: title,
                stopButton: AlarmButton(text: "Start routine", textColor: .white, systemImageName: "figure.jumprope")
            )
            let attributes = AlarmAttributes<WakeMetadata>(
                presentation: AlarmPresentation(alert: alert),
                tintColor: Theme.terracotta
            )
            let configuration = AlarmManager.AlarmConfiguration<WakeMetadata>.alarm(
                schedule: .fixed(planned.fireDate),
                attributes: attributes,
                stopIntent: StartRoutineIntent(),
                // Calming sound with a slow fade-in baked into the file, so it starts subtle.
                sound: .named(Store.alarmSound.alarmFile)
            )
            _ = try await manager.schedule(id: UUID(), configuration: configuration)
        }
    }
}
