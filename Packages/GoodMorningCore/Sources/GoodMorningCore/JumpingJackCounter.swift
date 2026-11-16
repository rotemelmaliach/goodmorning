import Foundation

/// A body joint in normalized image coordinates: x and y in 0...1, **y grows upward**
/// (the convention Apple's Vision framework uses).
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

    var allJoints: [PosePoint] {
        [
            leftWrist, rightWrist, leftElbow, rightElbow, leftShoulder, rightShoulder,
            leftHip, rightHip, leftKnee, rightKnee, leftAnkle, rightAnkle,
        ]
    }

    var shoulderY: Double { (leftShoulder.y + rightShoulder.y) / 2 }
    var hipY: Double { (leftHip.y + rightHip.y) / 2 }
    var kneeY: Double { (leftKnee.y + rightKnee.y) / 2 }
    var ankleY: Double { (leftAnkle.y + rightAnkle.y) / 2 }
    var shoulderWidth: Double { abs(leftShoulder.x - rightShoulder.x) }
    /// Shoulder line to hip line. The unit most pose thresholds are expressed in.
    var torso: Double { shoulderY - hipY }

    /// True when the whole body is in frame, upright, and tracked with enough confidence.
    func isWholeBodyVisible(minConfidence: Double) -> Bool {
        allJoints.allSatisfy { $0.confidence >= minConfidence } && shoulderWidth > 0.02 && torso > 0.02
    }
}

public enum RepResult: Sendable, Equatable {
    /// The whole body isn't visible with enough confidence. Tell the user to step back.
    case bodyNotVisible
    case tracking
    case repCompleted
}

/// Counts jumping jacks from a stream of pose frames.
/// One rep = closed (arms down, feet together) -> open (arms overhead, feet apart) -> closed.
/// Distances are measured in shoulder widths, so it works at any distance from the camera.
public struct JumpingJackCounter: Sendable {
    public struct Config: Sendable {
        public var minConfidence = 0.3
        /// Ankle spread, in shoulder widths, at or above which feet count as apart.
        public var openFeetRatio = 1.3
        /// Ankle spread, in shoulder widths, at or below which feet count as together.
        public var closedFeetRatio = 0.9
        /// Reps faster than this are treated as tracking noise.
        public var minRepSeconds = 0.3

        public init() {}
    }

    private enum Stance { case unknown, closed, open }

    public var config: Config
    public private(set) var reps = 0
    private var stance: Stance = .unknown
    private var reachedOpen = false
    private var lastRepTime: TimeInterval?

    public init(config: Config = Config()) {
        self.config = config
    }

    public mutating func ingest(_ frame: PoseFrame) -> RepResult {
        guard frame.isWholeBodyVisible(minConfidence: config.minConfidence) else { return .bodyNotVisible }

        let feetRatio = abs(frame.leftAnkle.x - frame.rightAnkle.x) / frame.shoulderWidth
        let armsUp = frame.leftWrist.y > frame.shoulderY && frame.rightWrist.y > frame.shoulderY
        let armsDownLine = frame.shoulderY - frame.torso / 2
        let armsDown = frame.leftWrist.y < armsDownLine && frame.rightWrist.y < armsDownLine

        if armsUp && feetRatio >= config.openFeetRatio {
            if stance == .closed { reachedOpen = true }
            stance = .open
        } else if armsDown && feetRatio <= config.closedFeetRatio {
            defer {
                stance = .closed
                reachedOpen = false
            }
            if reachedOpen {
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

/// Counts squats seen from the front. Going down, the thigh foreshortens: the hips drop toward
/// knee height. One rep = standing -> hips near knee height -> standing.
public struct SquatCounter: Sendable {
    public struct Config: Sendable {
        public var minConfidence = 0.3
        /// Thigh height divided by shin height at or below which the squat counts as deep enough.
        public var downRatio = 0.5
        /// The same ratio at or above which the user counts as standing again.
        public var upRatio = 0.8
        public var minRepSeconds = 0.6

        public init() {}
    }

    public var config: Config
    public private(set) var reps = 0
    private var hasStood = false
    private var wentDown = false
    private var lastRepTime: TimeInterval?

    public init(config: Config = Config()) {
        self.config = config
    }

    public mutating func ingest(_ frame: PoseFrame) -> RepResult {
        let shin = frame.kneeY - frame.ankleY
        guard frame.isWholeBodyVisible(minConfidence: config.minConfidence), shin > 0.02 else {
            return .bodyNotVisible
        }
        let ratio = (frame.hipY - frame.kneeY) / shin

        if ratio <= config.downRatio {
            if hasStood { wentDown = true }
        } else if ratio >= config.upRatio {
            hasStood = true
            if wentDown {
                wentDown = false
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
