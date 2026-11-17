# Good Morning: architecture

A personal iPhone + Apple Watch app (TestFlight only). The alarm goes off and the only way to
make it stay quiet is to complete a verified wake-up sequence.

## Decisions so far

| Topic | Decision |
|---|---|
| Platform | iOS 26+, watchOS 26+, SwiftUI |
| Alarm | Own alarms through AlarmKit (rings through silent mode and Focus). Apple's Clock app has no API, so we don't connect to it. |
| Strictness | Hard mode: no snooze, no skip. |
| Schedule | A wake time per weekday (default 07:30 Sun to Thu, 09:00 Fri and Sat; edited in a weekly calendar on the home screen, any day can be turned off). |
| Emergency exit | A day can be excused in advance only: at least 6 hours before its alarm. |
| Never-ending alarm | The in-app alarm rings from the first step until the front camera has counted 20 reps of the day's exercise (jumping jacks, squats, push-ups, or rotating daily). No fallback: nothing else silences it. |
| Routine | From `docs/wake-protocol.md`: sit 10 s, lights, one set of 20 reps to stop the alarm, then straight into eight standing stretches (15 s each, camera-checked), face splash, water. |
| Alarm sound | Five calming sounds synthesized by `tools/make_sounds.py` (chimes, singing bowl, ocean, harp, birds). The system alarm plays a file with a 20 s fade-in baked in; the in-app alarm ramps from 8% to full over 75 s (`AlarmVolumeRamp`) and jumps to full when a step runs over time. The phone's own volume setting still caps it. |
| Camera framing | The phone can't see the whole body. The user is asked to step back once (`FramingGate`: head to hips in view), then everything is counted from shoulders and arms: jumping jacks by arms down/up/down, squats by how far the shoulders sink. Push-ups use the same shoulder-drop counter with the phone on the floor (no step back; measured in upper-arm lengths so side-on works). A white stick figure is drawn over the selfie preview. |
| Look | Warm dawn palette (cream, peach, terracotta, sage) in `Theme.swift`, mirrored in the browser UI lab at `docs/ui-lab/index.html`. Motion follows the `emil-design-eng` skill in `.agents/skills`: presses shrink to 0.97 over 150 ms, one strong ease-out curve, UI under 300 ms, no bounce except the completion screen, staggered entrances, Reduce Motion respected. |
| After the routine | Summary screen with sleep stats, weather and today's calendar. |
| Verification | Phone pedometer, front camera body pose, Apple Watch heart rate |
| Build | No Mac. GitHub Actions macOS runner builds; XcodeGen generates the Xcode project from `project.yml`. |
| Storage | UserDefaults (single user, tiny data) |

## Layers

```
Packages/GoodMorningCore      Pure Swift, no Apple frameworks. Builds and tests on Windows.
  Routine.swift               Routine, RoutineStep, StepGoal (what verifies each step)
  RoutineEngine.swift         State machine: events in, effects out. No skip path.
  JumpingJackCounter.swift    Pose frames; jumping-jack and squat rep counters
  Stretch.swift               The stretch set and per-stretch pose checks
  AlarmPlanner.swift          Which alarms must exist (main + backups), streak maths

App/GoodMorning               iPhone app: thin adapters around the core
  Routine/RoutineSession      Runs the clock, picks the sensor per step, applies effects
  Alarm/AlarmService          AlarmKit scheduling from AlarmPlanner output
  Alarm/AlarmSoundPlayer      In-app tone while steps are unfinished (background audio)
  Sensors/PedometerSensor     CoreMotion step count  -> .stepsWalked
  Sensors/PoseCameraSensor    AVFoundation + Vision  -> .repCounted
  Sensors/WatchLink           WatchConnectivity      -> .heartRate
  UI/                         HomeView (alarm time, streak), RoutineView (no close button)

App/GoodMorningWatch          Watch app: workout session, streams heart rate to the phone
```

The rule: anything that is a decision lives in the core package and has a test. The app layer
only translates between Apple frameworks and core events/effects. That matters here because
the core is the only part that can be run on the development PC.

## How a morning goes

1. AlarmKit fires the main alarm (system full-screen alert, works when the phone is locked or silent).
2. The alert's button runs `StartRoutineIntent`, which opens the app and starts `RoutineEngine`.
3. Each step starts its sensor. The in-app tone rings on steps marked `alarmSounding`, and
   escalates on any step that runs past its time limit.
4. When the last step completes: tone off, history saved, today's remaining backup alarms cancelled,
   next days re-planned.

## How hard mode is enforced

iOS does not let an app stop you from silencing a system alarm or force-quitting an app. So
enforcement is by consequence instead:

- **Backup alarms.** Every wake day has the main alarm plus N backups (default 5, every 3 minutes).
  They are real AlarmKit alarms, already scheduled, and are only removed by finishing the routine.
  Stopping the alarm and going back to sleep, or killing the app, just means another alarm in 3 minutes.
- **Rolling window.** Alarms are planned 3 days ahead and re-planned on every launch and completion,
  so a missed day does not leave the next day unarmed.
- **No skip in the engine.** `RoutineEngine` has no abort or skip transition at all.

- **Advance skip only.** `WakeSchedule.skip` refuses anything with less than 6 hours of notice, so there is no exit available from bed.

## Known gaps and risks

- The app and watch targets have **not been compiled yet**; they were written on Windows. The
  first CI run will surface API signature fixes, most likely in `AlarmService` (AlarmKit is new).
- AlarmKit may cap the number of scheduled alarms. The plan uses up to 18; verify on device.
- iOS has no public ambient light sensor API, so "is the light on" can only be estimated from
  camera exposure.
- Pedometer updates lag a few seconds.
- The rep-gated alarm has no fallback by choice. If the camera cannot see the user (dark room, phone fell, camera permission revoked) the alarm cannot be silenced from inside the app, and the research's "I feel dizzy" alternative is not available while it rings.
- The walk step was removed at the user's request, so jumping can start right after the 10-second sit. The research protocol asks for about 20 seconds upright before any jumping.
- Pose thresholds are tuned on synthetic data only and need calibrating on a real body.
- Counting from the upper body is easier to cheat: raising and lowering both arms counts as a jumping jack, and bobbing the shoulders counts as a squat.
- The framing gate gives up after 15 s with a body in view and lets counting start anyway, so a badly placed phone can never trap the user with a ringing alarm.
- A quad stretch can only be checked when the legs are in frame; otherwise staying in view counts.
- The stick figure assumes the camera frames are mirrored like the preview; if it appears flipped on device, that is the setting to fix (`PoseCameraSensor.configure`).
- Stretches do not tell left from right; each side bend and quad stretch accepts either side.
- Parts of the researched protocol are not built yet:
  - lights-on check from camera brightness (currently a tap)
  - QR/NFC anchor at the sink (currently a tap)
  - restart-the-step on timeout (currently the tone escalates only)
  - the 20-minute no-return guard, the "I feel dizzy" alternative, the first-run health screen, and the reaction-time check
- `StepGoal.scanCode` exists in the core but has no camera sensor yet.

## Planned integrations

| Integration | Use |
|---|---|
| HealthKit | Last night's sleep on the summary screen; save the routine as a workout |
| Apple Watch | Wrist haptics with the alarm, heart-rate verification, sleep-stage-aware wake window |
| EventKit (Calendar) | First meeting of the day; suggest alarm time the night before |
| WeatherKit | Weather on the completion screen |
| App Intents / Shortcuts | "Routine finished" trigger for HomeKit lights, coffee machine plug, music |
| Focus | Turn off Sleep Focus when the routine completes |
