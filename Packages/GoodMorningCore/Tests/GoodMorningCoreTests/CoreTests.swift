import Foundation
import Testing

@testable import GoodMorningCore

private let t0 = Date(timeIntervalSince1970: 1_800_000_000)

private let threeSteps = Routine(
    name: "t",
    steps: [
        RoutineStep(id: "a", title: "", instruction: "", goal: .walk(steps: 20), timeLimit: 60, alarmSounding: true),
        RoutineStep(id: "b", title: "", instruction: "", goal: .reps(exercise: .jumpingJack, count: 20), timeLimit: 120),
        RoutineStep(id: "c", title: "", instruction: "", goal: .confirm, timeLimit: 120),
    ]
)

private var utc: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}

@Suite struct RoutineEngineTests {
    @Test func runsDefaultRoutineToCompletion() {
        var engine = RoutineEngine(routine: threeSteps)
        #expect(engine.start(at: t0) == [.stepBegan(index: 0), .alarmSound(.normal)])

        #expect(engine.handle(.stepsWalked(10), at: t0 + 5).isEmpty)
        #expect(engine.progress == 0.5)
        // Events for other sensors are ignored.
        #expect(engine.handle(.confirmed, at: t0 + 6).isEmpty)

        #expect(
            engine.handle(.stepsWalked(21), at: t0 + 10)
                == [.stepFinished(index: 0), .stepBegan(index: 1), .alarmSound(.off)]
        )
        for _ in 0..<19 { _ = engine.handle(.repCounted(.jumpingJack), at: t0 + 20) }
        #expect(engine.count == 19)
        _ = engine.handle(.repCounted(.jumpingJack), at: t0 + 30)
        #expect(engine.phase == .running(stepIndex: 2))

        let effects = engine.handle(.confirmed, at: t0 + 40)
        guard case .finished(let summary) = engine.phase else {
            Issue.record("expected finished")
            return
        }
        #expect(effects == [.stepFinished(index: 2), .alarmSound(.off), .routineFinished(summary)])
        #expect(summary.totalDuration == 40)
        #expect(summary.steps.map(\.duration) == [10, 20, 10])
    }

    @Test func escalatesOnceWhenOverTimeLimitButStillRequiresCompletion() {
        var engine = RoutineEngine(routine: threeSteps)
        _ = engine.start(at: t0)
        #expect(engine.tick(at: t0 + 59).isEmpty)
        #expect(engine.tick(at: t0 + 61) == [.alarmSound(.escalated)])
        #expect(engine.tick(at: t0 + 62).isEmpty)
        #expect(engine.phase == .running(stepIndex: 0))

        _ = engine.handle(.stepsWalked(20), at: t0 + 70)
        _ = engine.handle(.repCounted(.jumpingJack), at: t0 + 71)
        #expect(engine.phase == .running(stepIndex: 1))
    }

    @Test func heartRateMustBeHeldAndTimerCompletesOnTick() {
        let routine = Routine(
            name: "t",
            steps: [
                RoutineStep(id: "hr", title: "", instruction: "", goal: .heartRate(atLeastBPM: 100, holdSeconds: 10)),
                RoutineStep(id: "wait", title: "", instruction: "", goal: .timer(seconds: 5)),
            ]
        )
        var engine = RoutineEngine(routine: routine)
        _ = engine.start(at: t0)
        _ = engine.handle(.heartRate(bpm: 110), at: t0)
        _ = engine.handle(.heartRate(bpm: 90), at: t0 + 8)  // dropped: hold resets
        #expect(engine.tick(at: t0 + 11).isEmpty)
        _ = engine.handle(.heartRate(bpm: 105), at: t0 + 12)
        #expect(engine.tick(at: t0 + 21).isEmpty)
        let held = engine.tick(at: t0 + 22)
        #expect(held.contains(.stepFinished(index: 0)))

        #expect(engine.tick(at: t0 + 26).isEmpty)
        _ = engine.tick(at: t0 + 27)
        guard case .finished = engine.phase else {
            Issue.record("expected finished")
            return
        }
    }
}

/// A synthetic person facing the camera. Defaults are standing still, arms at the sides.
private func pose(
    _ time: TimeInterval,
    wristY: Double = 0.45,
    elbowY: Double = 0.58,
    ankleSpread: Double = 0.04,
    hipY: Double = 0.5,
    shoulderWidth: Double = 0.1,
    lean: Double = 0,
    leftAnkleY: Double = 0.1,
    confidence: Double = 1
) -> PoseFrame {
    func p(_ x: Double, _ y: Double) -> PosePoint { PosePoint(x: x, y: y, confidence: confidence) }
    let shoulderY = hipY + 0.2
    let half = shoulderWidth / 2
    return PoseFrame(
        time: time,
        leftWrist: p(0.4 + lean, wristY), rightWrist: p(0.6 + lean, wristY),
        leftElbow: p(0.38 + lean, elbowY), rightElbow: p(0.62 + lean, elbowY),
        leftShoulder: p(0.5 - half + lean, shoulderY), rightShoulder: p(0.5 + half + lean, shoulderY),
        leftHip: p(0.46, hipY), rightHip: p(0.54, hipY),
        leftKnee: p(0.47, 0.3), rightKnee: p(0.53, 0.3),
        leftAnkle: p(0.5 - ankleSpread, leftAnkleY), rightAnkle: p(0.5 + ankleSpread, 0.1)
    )
}

@Suite struct JumpingJackCounterTests {
    private func frame(_ time: TimeInterval, open: Bool, confidence: Double = 1) -> PoseFrame {
        pose(time, wristY: open ? 0.9 : 0.45, ankleSpread: open ? 0.18 : 0.04, confidence: confidence)
    }

    @Test func countsClosedOpenClosedAsOneRep() {
        var counter = JumpingJackCounter()
        #expect(counter.ingest(frame(0, open: false)) == .tracking)
        #expect(counter.ingest(frame(0.4, open: true)) == .tracking)
        #expect(counter.ingest(frame(0.8, open: false)) == .repCompleted)
        #expect(counter.ingest(frame(0.9, open: false)) == .tracking)
        #expect(counter.ingest(frame(1.2, open: true)) == .tracking)
        #expect(counter.ingest(frame(1.6, open: false)) == .repCompleted)
        #expect(counter.reps == 2)
    }

    @Test func startingWithArmsUpDoesNotCount() {
        var counter = JumpingJackCounter()
        _ = counter.ingest(frame(0, open: true))
        #expect(counter.ingest(frame(0.5, open: false)) == .tracking)
        #expect(counter.reps == 0)
    }

    @Test func rejectsLowConfidenceAndImpossiblyFastReps() {
        var counter = JumpingJackCounter()
        #expect(counter.ingest(frame(0, open: false, confidence: 0.1)) == .bodyNotVisible)
        _ = counter.ingest(frame(0, open: false))
        _ = counter.ingest(frame(0.4, open: true))
        _ = counter.ingest(frame(0.8, open: false))
        _ = counter.ingest(frame(0.85, open: true))
        #expect(counter.ingest(frame(0.9, open: false)) == .tracking)
        #expect(counter.reps == 1)
    }
}

@Suite struct SquatCounterTests {
    @Test func countsDownAndUpAndIgnoresHalfSquats() {
        var counter = RepCounter(exercise: .squat)
        #expect(counter.ingest(pose(0)) == .tracking)
        // Half squat: hips only drop a little. Not a rep.
        _ = counter.ingest(pose(1, hipY: 0.44))
        #expect(counter.ingest(pose(2)) == .tracking)
        // Full squat: hips near knee height, then stand.
        #expect(counter.ingest(pose(3, hipY: 0.36)) == .tracking)
        #expect(counter.ingest(pose(4)) == .repCompleted)
        // Starting already crouched doesn't count until the user has stood once.
        var crouched = SquatCounter()
        _ = crouched.ingest(pose(0, hipY: 0.36))
        #expect(crouched.ingest(pose(1)) == .tracking)
        #expect(crouched.reps == 0)
    }
}

@Suite struct StretchTests {
    @Test func holdOnlyAccruesWhileThePoseIsHeld() {
        var tracker = StretchTracker(stretch: .overheadReach)
        #expect(tracker.ingest(pose(0, wristY: 0.9)).credited == 0)  // first frame has no duration
        #expect(tracker.ingest(pose(0.25, wristY: 0.9)).credited == 0.25)
        #expect(tracker.ingest(pose(0.5)).credited == 0)  // arms dropped: paused
        #expect(tracker.ingest(pose(0.75, wristY: 0.9, confidence: 0.1)) == .init(bodyVisible: false, credited: 0))
    }

    @Test func recognisesEachHeldStretch() {
        func held(_ stretch: Stretch, _ frame: (TimeInterval) -> PoseFrame) -> Bool {
            var tracker = StretchTracker(stretch: stretch)
            _ = tracker.ingest(frame(0))
            return tracker.ingest(frame(0.25)).credited > 0
        }
        let r1 = held(.sideBendLeft) { pose($0, wristY: 0.8, lean: 0.07) }
        #expect(r1)
        let r2 = held(.sideBendLeft) { pose($0, wristY: 0.8) }
        #expect(!r2)
        let r3 = held(.cactusArms) { pose($0, wristY: 0.78, elbowY: 0.7) }
        #expect(r3)
        let r4 = held(.cactusArms) { pose($0) }
        #expect(!r4)
        let r5 = held(.quadRight) { pose($0, leftAnkleY: 0.3) }
        #expect(r5)
        let r6 = held(.quadRight) { pose($0) }
        #expect(!r6)
    }

    @Test func movingStretchesNeedContinuedMovement() {
        var circles = StretchTracker(stretch: .armCircles)
        _ = circles.ingest(pose(0, wristY: 0.9))
        #expect(circles.ingest(pose(0.5, wristY: 0.4)).credited == 0.5)  // up -> down: moving
        #expect(circles.ingest(pose(1, wristY: 0.9)).credited == 0.5)
        // Arms stay up: credit runs out after the grace period.
        #expect(circles.ingest(pose(1.5, wristY: 0.9)).credited > 0)
        _ = circles.ingest(pose(3.75, wristY: 0.9))
        #expect(circles.ingest(pose(4, wristY: 0.9)).credited == 0)

        var twists = StretchTracker(stretch: .trunkTwists)
        _ = twists.ingest(pose(0))
        #expect(twists.ingest(pose(0.5, shoulderWidth: 0.07)).credited == 0.5)
    }

    @Test func engineCompletesStretchStepOnAccumulatedTime() {
        let routine = Routine(
            name: "t",
            steps: [RoutineStep(id: "s", title: "", instruction: "", goal: .stretch(.cactusArms, seconds: 15))]
        )
        var engine = RoutineEngine(routine: routine)
        _ = engine.start(at: t0)
        #expect(engine.handle(.stretchHeld(.cactusArms, seconds: 10), at: t0 + 10).isEmpty)
        #expect(engine.handle(.stretchHeld(.quadLeft, seconds: 10), at: t0 + 20).isEmpty)  // wrong stretch
        #expect(engine.handle(.stretchHeld(.cactusArms, seconds: 5), at: t0 + 30).contains(.stepFinished(index: 0)))
    }
}

@Suite struct DefaultRoutineTests {
    @Test func alarmRingsUntilTheCameraCountsTheWakeReps() {
        let routine = Routine.researchedDefault(wakeExercise: .squat)
        let wake = routine.steps.firstIndex { $0.id == "wake-reps" }!
        #expect(routine.steps[wake].goal == .reps(exercise: .squat, count: 20))
        #expect(routine.steps[...wake].allSatisfy { $0.alarmSounding })
        #expect(routine.steps[(wake + 1)...].allSatisfy { !$0.alarmSounding })
        #expect(routine.steps.filter { $0.id.hasPrefix("stretch-") }.count == 8)

        var engine = RoutineEngine(routine: routine)
        _ = engine.start(at: t0)
        // Sit, then lights, then straight to the reps: no walking step.
        #expect(routine.steps.prefix(3).map(\.id) == ["sit", "lights", "wake-reps"])
        _ = engine.tick(at: t0 + 10)
        let afterLights = engine.handle(.confirmed, at: t0 + 40)
        #expect(afterLights == [.stepFinished(index: 1), .stepBegan(index: 2), .alarmSound(.normal)])
        // Nothing but camera-counted reps of the right exercise moves past this step.
        let tap = engine.handle(.confirmed, at: t0 + 50)
        let wrongExercise = engine.handle(.repCounted(.jumpingJack), at: t0 + 50)
        let muchLater = engine.tick(at: t0 + 4_000)
        #expect(tap.isEmpty)
        #expect(wrongExercise.isEmpty)
        #expect(muchLater == [.alarmSound(.escalated)])
        #expect(engine.phase == .running(stepIndex: 2))
        for _ in 0..<19 { _ = engine.handle(.repCounted(.squat), at: t0 + 4_010) }
        let lastRep = engine.handle(.repCounted(.squat), at: t0 + 4_020)
        #expect(lastRep == [.stepFinished(index: 2), .stepBegan(index: 3), .alarmSound(.off)])
    }

    @Test func mainJumpingJackSetIsHalvedWhenJacksAlreadyStoppedTheAlarm() {
        func mainSet(_ wake: Exercise) -> StepGoal? {
            Routine.researchedDefault(wakeExercise: wake).steps.first { $0.id == "jumping-jacks" }?.goal
        }
        #expect(mainSet(.jumpingJack) == .reps(exercise: .jumpingJack, count: 20))
        #expect(mainSet(.squat) == .reps(exercise: .jumpingJack, count: 40))
    }

    @Test func exerciseRotatesDayToDay() {
        #expect(Exercise.rotating(on: t0, calendar: utc) != Exercise.rotating(on: t0 + 86_400, calendar: utc))
    }
}

@Suite struct AlarmPlannerTests {
    // t0 is 2027-01-15 08:00:00 UTC, a Friday (weekday 6).
    @Test func plansMainAndBackupsAndSkipsPastAndUnscheduledDays() {
        let schedule = WakeSchedule(hour: 7, minute: 0, weekdays: [6, 1], backupCount: 2, backupIntervalMinutes: 3)
        let plan = AlarmPlanner.plan(schedule: schedule, from: t0, days: 3, calendar: utc)
        // Friday 07:00 already passed, Saturday is unscheduled, Sunday gets main + 2 backups.
        #expect(plan.count == 3)
        #expect(plan.map(\.backupIndex) == [0, 1, 2])
        #expect(plan[0].fireDate == t0 + 2 * 86_400 - 3_600)
        #expect(plan[2].fireDate == plan[0].fireDate + 360)
    }

    @Test func keepsRemainingBackupsForTodayUnlessCompleted() {
        let schedule = WakeSchedule(hour: 7, minute: 58, backupCount: 2, backupIntervalMinutes: 3)
        let pending = AlarmPlanner.plan(schedule: schedule, from: t0, days: 1, calendar: utc)
        #expect(pending.map(\.backupIndex) == [1, 2])
        let done = AlarmPlanner.plan(schedule: schedule, from: t0, days: 1, completedDay: t0, calendar: utc)
        #expect(done.isEmpty)
    }
}

@Suite struct WakeScheduleTests {
    // t0 is Friday 08:00 UTC.
    @Test func defaultIsWeekdaysAtSevenThirtyAndWeekendsLater() {
        let schedule = WakeSchedule()
        // Friday and Saturday are the weekend (09:00); Sunday is a 07:30 workday.
        #expect(schedule.alarmDate(on: t0, calendar: utc) == t0 + 3_600)
        #expect(schedule.alarmDate(on: t0 + 2 * 86_400, calendar: utc) == t0 + 2 * 86_400 - 1_800)
        #expect(schedule.alarmDate(on: t0 + 86_400, calendar: utc) == t0 + 86_400 + 3_600)
        #expect(schedule.alarmDate(on: t0 + 3 * 86_400, calendar: utc) == t0 + 3 * 86_400 - 1_800)
    }

    @Test func skipNeedsNoticeAndRemovesThatDaysAlarms() {
        var schedule = WakeSchedule(hour: 9, minute: 0, backupCount: 1)
        // Today's 09:00 alarm is one hour away: too late to excuse.
        let tooLate = schedule.skip(t0, now: t0, calendar: utc)
        #expect(!tooLate)
        // Tomorrow's is 25 hours away: allowed.
        let inTime = schedule.skip(t0 + 86_400, now: t0, calendar: utc)
        #expect(inTime)
        let plan = AlarmPlanner.plan(schedule: schedule, from: t0, days: 3, calendar: utc)
        #expect(plan.map(\.fireDate) == [t0 + 3_600, t0 + 3_780, t0 + 2 * 86_400 + 3_600, t0 + 2 * 86_400 + 3_780])
        // An excused day doesn't break the streak.
        #expect(
            Streak.current(
                completedDays: [t0], weekdays: schedule.weekdays, skippedDays: schedule.skippedDays,
                today: t0 + 2 * 86_400, calendar: utc
            ) == 1
        )
    }
}

@Suite struct StreakTests {
    @Test func countsScheduledDaysAndToleratesTodayPending() {
        let day = 86_400.0
        // Completed Thu and Wed; Friday (today) not yet done; weekdays exclude nothing.
        #expect(Streak.current(completedDays: [t0 - day, t0 - 2 * day], weekdays: Set(1...7), today: t0, calendar: utc) == 2)
        // Gap on Wednesday breaks it.
        #expect(Streak.current(completedDays: [t0 - day, t0 - 3 * day], weekdays: Set(1...7), today: t0, calendar: utc) == 1)
        // Wednesday (4) unscheduled: the gap is skipped.
        #expect(
            Streak.current(completedDays: [t0, t0 - day, t0 - 3 * day], weekdays: [1, 2, 3, 5, 6, 7], today: t0, calendar: utc) == 3
        )
    }
}
