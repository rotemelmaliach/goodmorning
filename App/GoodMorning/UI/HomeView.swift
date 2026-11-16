import GoodMorningCore
import SwiftUI

struct HomeView: View {
    @Environment(RoutineSession.self) private var session
    @State private var schedule = Store.schedule
    @State private var skipRefused = false
    @State private var wakeExercise = Store.wakeExercise

    private let calendar = Calendar.current
    private var tomorrow: Date { calendar.date(byAdding: .day, value: 1, to: .now) ?? .now }

    var body: some View {
        NavigationStack {
            Form {
                Section("Wake times") {
                    WeekCalendarView(schedule: $schedule)
                }
                Section {
                    Picker("Stops the alarm", selection: $wakeExercise) {
                        Text("Rotate daily").tag(Exercise?.none)
                        ForEach(Exercise.allCases, id: \.self) { exercise in
                            Text("20 \(exercise.title.lowercased())").tag(Exercise?.some(exercise))
                        }
                    }
                    .onChange(of: wakeExercise) { _, newValue in Store.wakeExercise = newValue }
                } footer: {
                    Text("The alarm keeps ringing until the camera has counted every rep. There is no other way to stop it.")
                }
                Section {
                    if schedule.skippedDays.contains(calendar.startOfDay(for: tomorrow)) {
                        Label("Tomorrow is excused", systemImage: "moon.zzz")
                    } else {
                        Button("Skip tomorrow") {
                            skipRefused = !schedule.skip(tomorrow, now: .now)
                        }
                    }
                } footer: {
                    Text(
                        skipRefused
                            ? "Too late: a day can only be skipped at least \(Int(WakeSchedule.skipNoticeHours)) hours before its alarm."
                            : "The only way out of a routine is to excuse the day the night before."
                    )
                }
                Section("Progress") {
                    LabeledContent("Streak", value: "\(Store.streak) days")
                    if let last = Store.history.last {
                        LabeledContent(
                            "Last routine",
                            value: Duration.seconds(last.totalDuration).formatted(.time(pattern: .minuteSecond))
                        )
                    }
                }
                Section {
                    Button("Test the routine now") { session.begin() }
                }
            }
            .navigationTitle("Good Morning")
            .onChange(of: schedule) { _, newValue in
                Store.schedule = newValue
                Task { await session.rearmAlarms() }
            }
        }
    }
}
