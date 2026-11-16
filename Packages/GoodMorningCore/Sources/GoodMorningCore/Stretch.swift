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
/// Known limit: left and right are not told apart (a mirrored front camera makes that unreliable),
/// so each side bend and quad stretch accepts either side.
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
        guard frame.isWholeBodyVisible(minConfidence: minConfidence) else {
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

    /// Which extreme of the movement the body is at: +1, -1, or nil when in between.
    private mutating func motionZone(_ frame: PoseFrame) -> Int? {
        switch stretch {
        case .armCircles:
            let wristY = (frame.leftWrist.y + frame.rightWrist.y) / 2
            if wristY > frame.shoulderY { return 1 }
            if wristY < frame.hipY { return -1 }
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
        let torso = frame.torso
        switch stretch {
        case .overheadReach:
            let line = frame.shoulderY + 0.6 * torso
            return frame.leftWrist.y > line && frame.rightWrist.y > line
        case .sideBendLeft, .sideBendRight:
            // Trunk tilted at least 15 degrees from vertical (tan 15° ≈ 0.27), top arm overhead.
            let lean = abs((frame.leftShoulder.x + frame.rightShoulder.x) / 2 - (frame.leftHip.x + frame.rightHip.x) / 2)
            let topWrist = max(frame.leftWrist.y, frame.rightWrist.y)
            return lean >= 0.27 * torso && topWrist > frame.shoulderY + 0.3 * torso
        case .cactusArms:
            func side(_ wrist: PosePoint, _ elbow: PosePoint, _ shoulder: PosePoint) -> Bool {
                abs(elbow.y - shoulder.y) <= 0.3 * torso && wrist.y >= elbow.y + 0.25 * torso
            }
            return side(frame.leftWrist, frame.leftElbow, frame.leftShoulder)
                && side(frame.rightWrist, frame.rightElbow, frame.rightShoulder)
        case .quadLeft, .quadRight:
            // One ankle lifted to the knee height of the standing leg.
            let margin = 0.1 * (frame.kneeY - min(frame.leftAnkle.y, frame.rightAnkle.y))
            return frame.leftAnkle.y >= frame.rightKnee.y - margin || frame.rightAnkle.y >= frame.leftKnee.y - margin
        case .armCircles, .trunkTwists:
            return false
        }
    }
}
