import GoodMorningCore
import SwiftUI

struct HomeView: View {
    @Environment(RoutineSession.self) private var session
    @State private var schedule = Store.schedule
    @State private var skipRefused = false
    @State private var wakeExercise = Store.wakeExercise
    @State private var alarmSound = Store.alarmSound
    @State private var preview = SoundPreview()

    private let calendar = Calendar.current
    private var tomorrow: Date { calendar.date(byAdding: .day, value: 1, to: .now) ?? .now }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                hero.entrance(0)
                Card("Your week", icon: "calendar") {
                    WeekCalendarView(schedule: $schedule)
                }
                .entrance(1)
                exerciseCard.entrance(2)
                soundCard.entrance(3)
                skipCard.entrance(4)
                progressCard.entrance(5)
                Button {
                    preview.stop()
                    session.begin()
                } label: {
                    Label("Try the routine now", systemImage: "play.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 6)
                .entrance(6)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 32)
        }
        .background(Theme.dawn.ignoresSafeArea())
        .onChange(of: schedule) { _, newValue in
            Store.schedule = newValue
            Task { await session.rearmAlarms() }
        }
        .onDisappear { preview.stop() }
    }

    // MARK: - Hero

    private var nextAlarm: Date? {
        AlarmPlanner.plan(schedule: schedule, from: .now, days: 8, completedDay: nil)
            .first { !$0.isBackup }?
            .fireDate
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Good Morning")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .opacity(0.9)
                Spacer()
                Label("\(Store.streak) day streak", systemImage: "flame.fill")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.22), in: Capsule())
            }
            if let next = nextAlarm {
                Text(next.formatted(date: .omitted, time: .shortened))
                    .font(Theme.title(64))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text("Next wake-up · \(dayLabel(next))")
                    .font(Theme.body.weight(.medium))
                    .opacity(0.92)
            } else {
                Text("No alarm set")
                    .font(Theme.title(40))
                Text("Pick a day below to set one.")
                    .font(Theme.body)
                    .opacity(0.92)
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background {
            ZStack(alignment: .topTrailing) {
                Theme.glow
                Circle()
                    .fill(Theme.sun.opacity(0.55))
                    .frame(width: 180, height: 180)
                    .blur(radius: 30)
                    .offset(x: 50, y: -60)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: Theme.terracotta.opacity(0.3), radius: 18, y: 10)
        .padding(.top, 8)
    }

    private func dayLabel(_ date: Date) -> String {
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        return date.formatted(.dateTime.weekday(.wide))
    }

    // MARK: - Exercise

    private var exerciseCard: some View {
        Card("Stops the alarm", icon: "figure.mixed.cardio") {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible())], spacing: 10) {
                exerciseChoice(nil, title: "Rotate daily", icon: "arrow.triangle.2.circlepath")
                exerciseChoice(.jumpingJack, title: "Jumping jacks", icon: "figure.mixed.cardio")
                exerciseChoice(.squat, title: "Squats", icon: "figure.strengthtraining.functional")
                exerciseChoice(.pushUp, title: "Push-ups", icon: "figure.core.training")
            }
            Text("One set of 20 reps, counted by the camera. The alarm keeps going until the last one. There is no other way to stop it.")
                .font(Theme.caption)
                .foregroundStyle(Theme.inkSoft)
        }
    }

    private func exerciseChoice(_ exercise: Exercise?, title: String, icon: String) -> some View {
        let isSelected = wakeExercise == exercise
        return Button {
            withAnimation(Theme.easeOut()) { wakeExercise = exercise }
            Store.wakeExercise = exercise
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.title2)
                Text(title)
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 76)
            .foregroundStyle(isSelected ? Color.white : Theme.ink)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(Theme.glow) : AnyShapeStyle(Theme.peach.opacity(0.35)))
            }
        }
        .buttonStyle(PressableStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Sound

    private var soundCard: some View {
        Card("Alarm sound", icon: "music.note") {
            VStack(spacing: 8) {
                ForEach(AlarmSound.allCases) { sound in
                    soundRow(sound)
                }
            }
            Text("Every sound starts barely audible and swells slowly.")
                .font(Theme.caption)
                .foregroundStyle(Theme.inkSoft)
        }
    }

    private func soundRow(_ sound: AlarmSound) -> some View {
        let isSelected = alarmSound == sound
        let isPlaying = preview.playing == sound
        return HStack(spacing: 12) {
            Button {
                preview.toggle(sound)
            } label: {
                Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(isPlaying ? Theme.sage : Theme.terracotta, in: Circle())
            }
            .buttonStyle(PressableStyle())
            .accessibilityLabel(isPlaying ? "Stop \(sound.title)" : "Play \(sound.title)")

            Button {
                withAnimation(Theme.easeOut()) { alarmSound = sound }
                Store.alarmSound = sound
                Task { await session.rearmAlarms() }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(sound.title).font(Theme.body.weight(.semibold)).foregroundStyle(Theme.ink)
                        Text(sound.detail).font(Theme.caption).foregroundStyle(Theme.inkSoft)
                    }
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isSelected ? Theme.sage : Theme.line)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle())
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        }
        .padding(10)
        .background(
            isSelected ? Theme.sageSoft.opacity(0.6) : Theme.canvas,
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }

    // MARK: - Skip and progress

    private var skipCard: some View {
        let excused = schedule.skippedDays.contains(calendar.startOfDay(for: tomorrow))
        return Card("Tomorrow", icon: "moon.zzz.fill") {
            if excused {
                Label("Tomorrow is excused", systemImage: "checkmark.seal.fill")
                    .font(Theme.body.weight(.medium))
                    .foregroundStyle(Theme.sage)
            } else {
                Button("Skip tomorrow") {
                    withAnimation(Theme.easeOut()) { skipRefused = !schedule.skip(tomorrow, now: .now) }
                }
                .buttonStyle(SoftButtonStyle())
            }
            Text(
                skipRefused
                    ? "Too late: a day can only be skipped at least \(Int(WakeSchedule.skipNoticeHours)) hours before its alarm."
                    : "The only way out of a routine is to excuse the day the night before."
            )
            .font(Theme.caption)
            .foregroundStyle(skipRefused ? Theme.clay : Theme.inkSoft)
        }
    }

    private var progressCard: some View {
        Card("Progress", icon: "chart.line.uptrend.xyaxis") {
            HStack(spacing: 10) {
                stat("\(Store.streak)", "day streak")
                stat("\(Store.history.count)", "mornings done")
                stat(lastDuration, "last routine")
            }
        }
    }

    private var lastDuration: String {
        guard let last = Store.history.last else { return "–" }
        return Duration.seconds(last.totalDuration).formatted(.time(pattern: .minuteSecond))
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(Theme.title(26)).foregroundStyle(Theme.ink).monospacedDigit()
            Text(label).font(Theme.caption).foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Theme.canvas, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
