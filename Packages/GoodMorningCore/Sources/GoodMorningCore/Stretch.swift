import Foundation

/// The standing stretch set from docs/wake-protocol.md section 2.1, in order.
public enum Stretch: String, Codable, Sendable, CaseIterable {
    case armCircles, overheadReach, sideBendLeft, sideBendRight, cactusArms, trunkTwists, quadLeft, quadRight

    public var title: String {
        switch self {
        case .armCircles: "Arm circles"
        case .overheadReach: "Overhead reach"
        case .sideBendLeft: "Side bend, left"
        case .sideBendRight: "Side bend, right"
        case .cactusArms: "Cactus arms"
        case .trunkTwists: "Slow trunk twists"
        case .quadLeft: "Quad stretch, left leg"
        case .quadRight: "Quad stretch, right leg"
        }
    }

    public var instruction: String {
        switch self {
        case .armCircles: "Big circles with straight arms, forward then backward."
        case .overheadReach: "Hands together, reach up and rise onto your toes."
        case .sideBendLeft: "Right arm overhead, lean to the left."
        case .sideBendRight: "Left arm overhead, lean to the right."
        case .cactusArms: "Elbows out at shoulder height, forearms up, squeeze your shoulder blades."
        case .trunkTwists: "Arms bent at chest height, rotate slowly side to side, hips facing forward."
        case .quadLeft: "Pull your left heel toward your buttock. Hold a wall if you need to."
        case .quadRight: "Pull your right heel toward your buttock. Hold a wall if you need to."
        }
    }

    /// Moving stretches are judged by continued motion, the others by holding a pose.
    var isMoving: Bool { self == .armCircles || self == .trunkTwists }
}

/// Watches pose frames for one stretch and reports how much valid stretching time each frame adds.
/// Time only accrues while the pose is held (or the movement keeps going), so the step's
/// countdown pauses whenever the user stops.
///
/// Every stretch is judged from the upper body, because the legs are usually out of frame.
/// Known limits:
/// - left and right are not told apart (a mirrored front camera makes that unreliable), so each
///   side bend and quad stretch accepts either side;
/// - a quad stretch can only be checked when the legs are visible. When they aren't, the time
///   counts as long as the user stays in view.
public struct StretchTracker: Sendable {
    public struct Output: Sendable, Equatable {
        public var bodyVisible: Bool
        /// Seconds of valid stretching credited by this frame.
        public var credited: TimeInterval
    }

    public let stretch: Stretch
    public var minConfidence = 0.3
    /// A moving stretch keeps counting for this long after the last detected movement.
    public var motionGraceSeconds = 2.5

    private var lastFrameTime: TimeInterval?
    private var zone = 0
    private var lastMotionTime: TimeInterval?
    private var widestShoulders = 0.0

    public init(stretch: Stretch) {
        self.stretch = stretch
    }

    public mutating func ingest(_ frame: PoseFrame) -> Output {
        let elapsed = lastFrameTime.map { min(max(frame.time - $0, 0), 0.5) } ?? 0
        lastFrameTime = frame.time
        guard frame.hasShoulders(minConfidence), needsArms ? armsSeen(frame) : true else {
            return Output(bodyVisible: false, credited: 0)
        }

        let active: Bool
        if stretch.isMoving {
            if let newZone = motionZone(frame), newZone != zone {
                if zone != 0 { lastMotionTime = frame.time }
                zone = newZone
            }
            active = lastMotionTime.map { frame.time - $0 <= motionGraceSeconds } ?? false
        } else {
            active = isHeld(frame)
        }
        return Output(bodyVisible: true, credited: active ? elapsed : 0)
    }

    private var needsArms: Bool {
        switch stretch {
        case .trunkTwists, .quadLeft, .quadRight: false
        default: true
        }
    }

    private func armsSeen(_ frame: PoseFrame) -> Bool {
        let arms = frame.arms(minConfidence)
        return arms.left != .unknown && arms.right != .unknown
    }

    /// Which extreme of the movement the body is at: +1, -1, or nil when in between.
    private mutating func motionZone(_ frame: PoseFrame) -> Int? {
        switch stretch {
        case .armCircles:
            let arms = frame.arms(minConfidence)
            if arms.left == .up && arms.right == .up { return 1 }
            if arms.left == .down && arms.right == .down { return -1 }
            return nil
        case .trunkTwists:
            // Rotating the trunk makes the shoulders look narrower from the front.
            widestShoulders = max(widestShoulders, frame.shoulderWidth)
            if frame.shoulderWidth <= widestShoulders * 0.8 { return -1 }
            if frame.shoulderWidth >= widestShoulders * 0.92 { return 1 }
            return nil
        default:
            return nil
        }
    }

    private func isHeld(_ frame: PoseFrame) -> Bool {
        let torso = frame.torso(minConfidence)
        let arms = frame.arms(minConfidence)
        switch stretch {
        case .overheadReach:
            // Wrists well above the shoulders; if the hands leave the top of the frame,
            // raised elbows are enough.
            func reaching(_ wrist: PosePoint, _ state: PoseFrame.ArmState) -> Bool {
                wrist.confidence >= minConfidence ? wrist.y > frame.shoulderY + 0.6 * torso : state == .up
            }
            return reaching(frame.leftWrist, arms.left) && reaching(frame.rightWrist, arms.right)
        case .sideBendLeft, .sideBendRight:
            // Trunk tilted at least 15 degrees (tan 15° ≈ 0.27): the shoulders shift sideways
            // over the hips, or, with the hips out of frame, the shoulder line tilts.
            let leaning: Bool
            if frame.hasHips(minConfidence) {
                let shift = (frame.leftShoulder.x + frame.rightShoulder.x) / 2 - (frame.leftHip.x + frame.rightHip.x) / 2
                leaning = abs(shift) >= 0.27 * torso
            } else {
                leaning = abs(frame.leftShoulder.y - frame.rightShoulder.y) >= 0.2 * frame.shoulderWidth
            }
            return leaning && (arms.left == .up || arms.right == .up)
        case .cactusArms:
            func side(_ wrist: PosePoint, _ elbow: PosePoint) -> Bool {
                frame.seen(wrist, elbow, minConfidence: minConfidence)
                    && abs(elbow.y - frame.shoulderY) <= 0.3 * torso
                    && wrist.y >= elbow.y + 0.25 * torso
            }
            return side(frame.leftWrist, frame.leftElbow) && side(frame.rightWrist, frame.rightElbow)
        case .quadLeft, .quadRight:
            guard frame.hasLegs(minConfidence) else { return true }
            // One ankle lifted to the knee height of the standing leg.
            let margin = 0.1 * (frame.kneeY - min(frame.leftAnkle.y, frame.rightAnkle.y))
            return frame.leftAnkle.y >= frame.rightKnee.y - margin || frame.rightAnkle.y >= frame.leftKnee.y - margin
        case .armCircles, .trunkTwists:
            return false
        }
    }
}
