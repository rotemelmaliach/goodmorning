import Foundation

/// The standing stretch set from docs/wake-protocol.md section 2.1, in order.
///
/// Stretches are guided, not verified: the screen shows a demonstration photo and the step
/// moves on by itself after `seconds`. The camera is only used for the reps that stop the alarm.
public enum Stretch: String, Codable, Sendable, CaseIterable {
    case armCircles, overheadReach, sideBends, cactusArms, trunkTwists, quadLeft, quadRight

    /// One part of a stretch: what the demonstration shows and what the label says.
    public struct Phase: Sendable, Equatable {
        /// Shown over the photo when a stretch has more than one part ("Left side").
        public var label: String?
        /// Name of the demonstration photo in the app's asset catalog.
        public var image: String
        /// The photo is flipped left-to-right (one photo serves both sides).
        public var mirrored: Bool
    }

    public var title: String {
        switch self {
        case .armCircles: "Arm circles"
        case .overheadReach: "Overhead reach"
        case .sideBends: "Side bends"
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
        case .sideBends: "One arm overhead and lean away from it. Five seconds each side."
        case .cactusArms: "Upper arms straight out at shoulder height, forearms pointing up like a goalpost. Squeeze your shoulder blades together."
        case .trunkTwists: "Arms bent at chest height, rotate slowly side to side, hips facing forward."
        case .quadLeft: "Pull your left heel toward your buttock. Hold a wall if you need to."
        case .quadRight: "Pull your right heel toward your buttock. Hold a wall if you need to."
        }
    }

    /// How long the step lasts.
    public var seconds: TimeInterval {
        self == .sideBends ? 10 : 15
    }

    /// The parts of the stretch, each lasting an equal share of `seconds`.
    public var phases: [Phase] {
        switch self {
        case .armCircles: [Phase(label: nil, image: "stretch-arm-circles", mirrored: false)]
        case .overheadReach: [Phase(label: nil, image: "stretch-overhead-reach", mirrored: false)]
        case .sideBends:
            [
                // The photo leans toward the right of the picture. The demonstration reads
                // like a mirror, so unflipped is the viewer's right.
                Phase(label: "Lean left", image: "stretch-side-bend", mirrored: true),
                Phase(label: "Lean right", image: "stretch-side-bend", mirrored: false),
            ]
        case .cactusArms: [Phase(label: nil, image: "stretch-cactus-arms", mirrored: false)]
        case .trunkTwists: [Phase(label: nil, image: "stretch-trunk-twists", mirrored: false)]
        case .quadLeft: [Phase(label: nil, image: "stretch-quad", mirrored: false)]
        case .quadRight: [Phase(label: nil, image: "stretch-quad", mirrored: true)]
        }
    }

    /// The part to show when the step is `progress` (0...1) of the way through.
    public func phase(at progress: Double) -> Phase {
        let all = phases
        let index = min(Int(max(progress, 0) * Double(all.count)), all.count - 1)
        return all[index]
    }
}
