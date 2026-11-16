import Foundation

public struct WakeTime: Codable, Sendable, Equatable {
    public var hour: Int
    public var minute: Int

    public init(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
    }
}

public struct WakeSchedule: Codable, Sendable, Equatable {
    /// Wake time per calendar weekday: 1 = Sunday ... 7 = Saturday. A missing weekday has no alarm.
    public var times: [Int: WakeTime]
    /// Days (start of day) the user excused in advance. This is the only way out of a routine.
    public var skippedDays: Set<Date>
    /// Extra alarms after the main one. They are only cancelled when the routine is completed,
    /// which is what makes stopping the first alarm and going back to sleep not work.
    public var backupCount: Int
    public var backupIntervalMinutes: Int

    /// A day can only be excused at least this long before its alarm ("the night before").
    public static let skipNoticeHours = 6.0

    /// Default: 07:30 Sunday to Thursday, 09:00 on Friday and Saturday (the user's weekend).
    public init(
        times: [Int: WakeTime]? = nil,
        skippedDays: Set<Date> = [],
        backupCount: Int = 5,
        backupIntervalMinutes: Int = 3
    ) {
        self.times = times ?? Dictionary(uniqueKeysWithValues: (1...7).map {
            ($0, (1...5).contains($0) ? WakeTime(hour: 7, minute: 30) : WakeTime(hour: 9, minute: 0))
        })
        self.skippedDays = skippedDays
        self.backupCount = backupCount
        self.backupIntervalMinutes = backupIntervalMinutes
    }

    /// Same time on every listed weekday.
    public init(hour: Int, minute: Int, weekdays: Set<Int> = Set(1...7), backupCount: Int = 5, backupIntervalMinutes: Int = 3) {
        let time = WakeTime(hour: hour, minute: minute)
        self.init(
            times: Dictionary(uniqueKeysWithValues: weekdays.map { ($0, time) }),
            backupCount: backupCount,
            backupIntervalMinutes: backupIntervalMinutes
        )
    }

    public var weekdays: Set<Int> { Set(times.keys) }

    /// The main alarm on the given day, or nil if that day has none or was excused.
    public func alarmDate(on day: Date, calendar: Calendar = .current) -> Date? {
        let start = calendar.startOfDay(for: day)
        guard
            !skippedDays.contains(start),
            let time = times[calendar.component(.weekday, from: start)]
        else { return nil }
        return calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: start)
    }

    /// Excuses a day. Refused (returns false) with less than `skipNoticeHours` of notice,
    /// so it can't be used from bed when the alarm is ringing.
    public mutating func skip(_ day: Date, now: Date, calendar: Calendar = .current) -> Bool {
        guard
            let alarm = alarmDate(on: day, calendar: calendar),
            alarm.timeIntervalSince(now) >= Self.skipNoticeHours * 3600
        else { return false }
        skippedDays.insert(calendar.startOfDay(for: day))
        return true
    }
}

public struct PlannedAlarm: Sendable, Equatable {
    public var fireDate: Date
    /// 0 for the main alarm, 1...n for backups.
    public var backupIndex: Int
    /// Start of the day this alarm belongs to.
    public var wakeDay: Date

    public var isBackup: Bool { backupIndex > 0 }
}

public enum AlarmPlanner {
    /// All alarms that should exist for the next `days` days, strictly after `now`.
    /// Pass `completedDay` to leave out the rest of a day whose routine is already done.
    public static func plan(
        schedule: WakeSchedule,
        from now: Date,
        days: Int = 3,
        completedDay: Date? = nil,
        calendar: Calendar = .current
    ) -> [PlannedAlarm] {
        let today = calendar.startOfDay(for: now)
        let completed = completedDay.map { calendar.startOfDay(for: $0) }
        var alarms: [PlannedAlarm] = []

        for offset in 0..<days {
            guard
                let day = calendar.date(byAdding: .day, value: offset, to: today),
                day != completed,
                let main = schedule.alarmDate(on: day, calendar: calendar)
            else { continue }

            for index in 0...max(0, schedule.backupCount) {
                let fireDate = main.addingTimeInterval(Double(index * schedule.backupIntervalMinutes) * 60)
                if fireDate > now {
                    alarms.append(PlannedAlarm(fireDate: fireDate, backupIndex: index, wakeDay: day))
                }
            }
        }
        return alarms
    }
}

public enum Streak {
    /// Consecutive scheduled days with a completed routine, counting back from today.
    /// Today not being done yet doesn't break the streak; unscheduled and excused days are skipped.
    public static func current(
        completedDays: [Date],
        weekdays: Set<Int>,
        skippedDays: Set<Date> = [],
        today: Date,
        calendar: Calendar = .current
    ) -> Int {
        let done = Set(completedDays.map { calendar.startOfDay(for: $0) })
        var day = calendar.startOfDay(for: today)
        var streak = 0

        if !done.contains(day), let previous = calendar.date(byAdding: .day, value: -1, to: day) {
            day = previous
        }
        for _ in 0..<3650 {
            if weekdays.contains(calendar.component(.weekday, from: day)), !skippedDays.contains(day) {
                guard done.contains(day) else { break }
                streak += 1
            }
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
    }
}
