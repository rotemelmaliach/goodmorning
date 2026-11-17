import Foundation

/// A body joint in image coordinates. **x and y share one unit** (the image height) and
/// **y grows upward** (the convention Apple's Vision framework uses), so distances can be
/// compared across axes. The camera layer scales x by the image's width / height.
public struct PosePoint: Sendable, Equatable {
    public var x: Double
    public var y: Double
    public var confidence: Double

    public init(x: Double, y: Double, confidence: Double = 1) {
        self.x = x
        self.y = y
        self.confidence = confidence
    }
}

/// One camera frame's joints. The phone usually can't see the whole body, so every reader
/// of a frame has to cope with joints that are missing (low confidence): legs are a bonus,
/// shoulders and arms are what counting relies on.
public struct PoseFrame: Sendable, Equatable {
    public var time: TimeInterval
    public var leftWrist, rightWrist: PosePoint
    public var leftElbow, rightElbow: PosePoint
    public var leftShoulder, rightShoulder: PosePoint
    public var leftHip, rightHip: PosePoint
    public var leftKnee, rightKnee: PosePoint
    public var leftAnkle, rightAnkle: PosePoint

    public init(
        time: TimeInterval,
        leftWrist: PosePoint, rightWrist: PosePoint,
        leftElbow: PosePoint, rightElbow: PosePoint,
        leftShoulder: PosePoint, rightShoulder: PosePoint,
        leftHip: PosePoint, rightHip: PosePoint,
        leftKnee: PosePoint, rightKnee: PosePoint,
        leftAnkle: PosePoint, rightAnkle: PosePoint
    ) {
        self.time = time
        self.leftWrist = leftWrist
        self.rightWrist = rightWrist
        self.leftElbow = leftElbow
        self.rightElbow = rightElbow
        self.leftShoulder = leftShoulder
        self.rightShoulder = rightShoulder
        self.leftHip = leftHip
        self.rightHip = rightHip
        self.leftKnee = leftKnee
        self.rightKnee = rightKnee
        self.leftAnkle = leftAnkle
        self.rightAnkle = rightAnkle
    }

    var shoulderY: Double { (leftShoulder.y + rightShoulder.y) / 2 }
    var hipY: Double { (leftHip.y + rightHip.y) / 2 }
    var kneeY: Double { (leftKnee.y + rightKnee.y) / 2 }
    var shoulderWidth: Double { abs(leftShoulder.x - rightShoulder.x) }

    func seen(_ points: PosePoint..., minConfidence: Double) -> Bool {
        points.allSatisfy { $0.confidence >= minConfidence }
    }

    func hasShoulders(_ minConfidence: Double) -> Bool {
        seen(leftShoulder, rightShoulder, minConfidence: minConfidence) && shoulderWidth > 0.02
    }

    func hasHips(_ minConfidence: Double) -> Bool {
        seen(leftHip, rightHip, minConfidence: minConfidence) && shoulderY - hipY > 0.02
    }

    func hasLegs(_ minConfidence: Double) -> Bool {
        seen(leftKnee, rightKnee, leftAnkle, rightAnkle, minConfidence: minConfidence)
    }

    /// Shoulder line to hip line: the unit pose thresholds are expressed in. When the hips are
    /// out of frame it is estimated from the shoulder width (a torso is about 1.4 shoulders).
    func torso(_ minConfidence: Double) -> Double {
        hasHips(minConfidence) ? shoulderY - hipY : shoulderWidth * 1.4
    }

    enum ArmState { case up, down, middle, unknown }

    /// Where one arm is, judged from the wrist, or from the elbow when the hand is cropped
    /// out of the frame (overhead at the top, hanging at the bottom).
    func arm(wrist: PosePoint, elbow: PosePoint, minConfidence: Double) -> ArmState {
        let unit = torso(minConfidence)
        if wrist.confidence >= minConfidence {
            if wrist.y > shoulderY + 0.25 * unit { return .up }
            if wrist.y < shoulderY - 0.5 * unit { return .down }
            return .middle
        }
        if elbow.confidence >= minConfidence {
            if elbow.y > shoulderY + 0.1 * unit { return .up }
            if elbow.y < shoulderY - 0.35 * unit { return .down }
            return .middle
        }
        return .unknown
    }

    func arms(_ minConfidence: Double) -> (left: ArmState, right: ArmState) {
        (
            arm(wrist: leftWrist, elbow: leftElbow, minConfidence: minConfidence),
            arm(wrist: rightWrist, elbow: rightElbow, minConfidence: minConfidence)
        )
    }
}

public enum RepResult: Sendable, Equatable {
    /// The joints this exercise is counted from aren't visible. Tell the user to step back.
    case bodyNotVisible
    case tracking
    case repCompleted
}

/// Counts jumping jacks from the arms alone, so it works when the legs are out of frame.
/// One rep = arms down -> both arms overhead -> arms down.
public struct JumpingJackCounter: Sendable {
    public struct Config: Sendable {
        public var minConfidence = 0.3
        /// Reps faster than this are treated as tracking noise.
        public var minRepSeconds = 0.3

        public init() {}
    }

    public var config: Config
    public private(set) var reps = 0
    private var wasDown = false
    private var reachedUp = false
    private var lastRepTime: TimeInterval?

    public init(config: Config = Config()) {
        self.config = config
    }

    public mutating func ingest(_ frame: PoseFrame) -> RepResult {
        guard frame.hasShoulders(config.minConfidence) else { return .bodyNotVisible }
        let arms = frame.arms(config.minConfidence)
        guard arms.left != .unknown, arms.right != .unknown else { return .bodyNotVisible }

        if arms.left == .up && arms.right == .up {
            if wasDown { reachedUp = true }
        } else if arms.left == .down && arms.right == .down {
            defer {
                wasDown = true
                reachedUp = false
            }
            if reachedUp {
                if let last = lastRepTime, frame.time - last < config.minRepSeconds {
                    return .tracking
                }
                lastRepTime = frame.time
                reps += 1
                return .repCompleted
            }
        }
        return .tracking
    }
}

/// Counts squats from how far the shoulders sink, so it works when the legs are out of frame.
/// One rep = standing -> shoulders drop by most of a shoulder width -> standing again.
public struct SquatCounter: Sendable {
    public struct Config: Sendable {
        public var minConfidence = 0.3
        /// Shoulder drop, in shoulder widths, at or beyond which the squat is deep enough.
        public var downDrop = 0.7
        /// Shoulder drop, in shoulder widths, at or below which the user is standing again.
        public var upDrop = 0.25
        public var minRepSeconds = 0.6
        /// How quickly the standing height follows the user when they drift (seconds).
        public var baselineSeconds = 3.0

        public init() {}
    }

    public var config: Config
    public private(set) var reps = 0
    private var standingY: Double?
    private var wentDown = false
    private var lastRepTime: TimeInterval?
    private var lastFrameTime: TimeInterval?

    public init(config: Config = Config()) {
        self.config = config
    }

    public mutating func ingest(_ frame: PoseFrame) -> RepResult {
        guard frame.hasShoulders(config.minConfidence) else { return .bodyNotVisible }
        let elapsed = lastFrameTime.map { max(frame.time - $0, 0) } ?? 0
        lastFrameTime = frame.time

        let y = frame.shoulderY
        guard var standing = standingY else {
            standingY = y
            return .tracking
        }
        if y > standing { standing = y }
        let drop = (standing - y) / frame.shoulderWidth

        defer { standingY = standing }
        if drop >= config.downDrop {
            wentDown = true
        } else if drop <= config.upDrop {
            if wentDown {
                wentDown = false
                if let last = lastRepTime, frame.time - last < config.minRepSeconds {
                    return .tracking
                }
                lastRepTime = frame.time
                reps += 1
                return .repCompleted
            }
            // Standing: let the reference height follow slow drift (walking, re-propped phone).
            standing += (y - standing) * min(1, elapsed / config.baselineSeconds)
        }
        return .tracking
    }
}

/// One counter for whichever exercise a step asks for.
public struct RepCounter: Sendable {
    public let exercise: Exercise
    private var jacks = JumpingJackCounter()
    private var squats = SquatCounter()

    public init(exercise: Exercise) {
        self.exercise = exercise
    }

    public mutating func ingest(_ frame: PoseFrame) -> RepResult {
        switch exercise {
        case .jumpingJack: jacks.ingest(frame)
        case .squat: squats.ingest(frame)
        }
    }
}

/// Asks the user to step back once, at the first camera step, before counting starts.
/// "Framed" means head-to-hips in view with room above the shoulders for raised arms.
/// The whole body is never required: the phone is propped near the bed and can't see it.
public struct FramingGate: Sendable {
    public enum State: Sendable, Equatable {
        /// Nobody in view yet.
        case noBody
        /// Someone is there but too close, or cut off at the hips or the top.
        case stepBack
        /// Framed; holding for a moment before counting starts.
        case holdStill
        case ready
    }

    public var minConfidence = 0.3
    /// Shoulder width as a share of the image height above which the user is too close.
    public var maxShoulderWidth = 0.24
    /// Shoulders must sit below this height (0 bottom, 1 top) so raised arms stay in frame.
    public var maxShoulderY = 0.72
    public var holdSeconds = 0.8
    /// The alarm has no other off switch, so the gate must never trap the user: once a body
    /// has been in view this long, counting starts with whatever framing there is.
    public var giveUpSeconds = 15.0

    public private(set) var state: State = .noBody
    private var framedSince: TimeInterval?
    private var firstSeen: TimeInterval?

    public init() {}

    public mutating func ingest(_ frame: PoseFrame) -> State {
        guard state != .ready else { return .ready }
        guard frame.hasShoulders(minConfidence) else {
            framedSince = nil
            state = .noBody
            return state
        }
        let seenAt = firstSeen ?? frame.time
        firstSeen = seenAt

        let framed =
            frame.hasHips(minConfidence)
            && frame.shoulderWidth <= maxShoulderWidth
            && frame.shoulderY <= maxShoulderY
        if framed {
            let since = framedSince ?? frame.time
            framedSince = since
            state = frame.time - since >= holdSeconds ? .ready : .holdStill
        } else {
            framedSince = nil
            state = .stepBack
        }
        if frame.time - seenAt >= giveUpSeconds { state = .ready }
        return state
    }
}
