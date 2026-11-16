import GoodMorningCore
import SwiftUI

/// The week at a glance: one tile per day showing its wake time. Tap a day to change its time
/// or turn its alarm off.
struct WeekCalendarView: View {
    @Binding var schedule: WakeSchedule
    @State private var selected = Calendar.current.component(.weekday, from: .now)

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 6) {
                ForEach(1...7, id: \.self) { weekday in
                    Button {
                        selected = weekday
                    } label: {
                        VStack(spacing: 6) {
                            Text(calendar.veryShortWeekdaySymbols[weekday - 1])
                                .font(.caption.bold())
                            Text(label(for: weekday))
                                .font(.caption2)
                                .monospacedDigit()
                                .minimumScaleFactor(0.7)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .foregroundStyle(schedule.times[weekday] == nil ? .secondary : .primary)
                        .background(
                            selected == weekday ? Color.accentColor.opacity(0.25) : Color.secondary.opacity(0.12),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(calendar.weekdaySymbols[weekday - 1]), \(label(for: weekday))")
                }
            }

            Toggle("\(calendar.weekdaySymbols[selected - 1]) alarm", isOn: enabledBinding)
            if schedule.times[selected] != nil {
                DatePicker("Wake up at", selection: timeBinding, displayedComponents: .hourAndMinute)
            }
        }
    }

    private func label(for weekday: Int) -> String {
        guard let time = schedule.times[weekday] else { return "Off" }
        return String(format: "%d:%02d", time.hour, time.minute)
    }

    private var enabledBinding: Binding<Bool> {
        Binding {
            schedule.times[selected] != nil
        } set: { isOn in
            schedule.times[selected] = isOn ? WakeTime(hour: 7, minute: 30) : nil
        }
    }

    private var timeBinding: Binding<Date> {
        Binding {
            let time = schedule.times[selected] ?? WakeTime(hour: 7, minute: 30)
            return calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: .now) ?? .now
        } set: { newValue in
            let parts = calendar.dateComponents([.hour, .minute], from: newValue)
            schedule.times[selected] = WakeTime(hour: parts.hour ?? 7, minute: parts.minute ?? 30)
        }
    }
}
