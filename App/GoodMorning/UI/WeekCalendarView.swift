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
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { selected = weekday }
                    } label: {
                        dayTile(weekday)
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityLabel("\(calendar.weekdaySymbols[weekday - 1]), \(label(for: weekday))")
                }
            }

            VStack(spacing: 12) {
                Toggle(isOn: enabledBinding) {
                    Text("\(calendar.weekdaySymbols[selected - 1]) alarm")
                        .font(Theme.body.weight(.medium))
                        .foregroundStyle(Theme.ink)
                }
                .tint(Theme.sage)

                if schedule.times[selected] != nil {
                    HStack(spacing: 10) {
                        Button("−15 min") { shift(-15) }.buttonStyle(SoftButtonStyle())
                        Spacer(minLength: 0)
                        DatePicker("Wake up at", selection: timeBinding, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                        Spacer(minLength: 0)
                        Button("+15 min") { shift(15) }.buttonStyle(SoftButtonStyle())
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(14)
            .background(Theme.canvas, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private func dayTile(_ weekday: Int) -> some View {
        let isOn = schedule.times[weekday] != nil
        let isSelected = selected == weekday
        return VStack(spacing: 6) {
            Text(calendar.veryShortWeekdaySymbols[weekday - 1])
                .font(.system(.caption, design: .rounded).weight(.bold))
            Text(label(for: weekday))
                .font(.system(.caption2, design: .rounded).weight(.medium))
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 58)
        .foregroundStyle(isSelected ? Color.white : (isOn ? Theme.ink : Theme.inkSoft.opacity(0.7)))
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isSelected ? AnyShapeStyle(Theme.glow) : AnyShapeStyle(isOn ? Theme.peach.opacity(0.45) : Theme.line.opacity(0.6)))
        }
        .scaleEffect(isSelected ? 1.06 : 1)
    }

    private func label(for weekday: Int) -> String {
        guard let time = schedule.times[weekday] else { return "Off" }
        return String(format: "%d:%02d", time.hour, time.minute)
    }

    private func shift(_ minutes: Int) {
        guard let time = schedule.times[selected] else { return }
        let total = ((time.hour * 60 + time.minute + minutes) % 1440 + 1440) % 1440
        withAnimation(.snappy) { schedule.times[selected] = WakeTime(hour: total / 60, minute: total % 60) }
    }

    private var enabledBinding: Binding<Bool> {
        Binding {
            schedule.times[selected] != nil
        } set: { isOn in
            withAnimation(.snappy) { schedule.times[selected] = isOn ? WakeTime(hour: 7, minute: 30) : nil }
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
