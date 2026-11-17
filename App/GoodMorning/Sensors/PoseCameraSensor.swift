import AVFoundation
import GoodMorningCore
import Observation
import Vision

/// The joints drawn over the selfie preview as a stick figure.
struct BodySkeleton: Equatable {
    enum Joint: Hashable {
        case nose, neck, root
        case leftShoulder, rightShoulder, leftElbow, rightElbow, leftWrist, rightWrist
        case leftHip, rightHip, leftKnee, rightKnee, leftAnkle, rightAnkle
    }

    /// Normalized 0...1 positions in the mirrored, upright camera image, origin top-left.
    /// Only joints the camera actually sees are present.
    var points: [Joint: CGPoint]
    /// Image width / height, needed to lay the points over an aspect-fill preview.
    var imageAspect: CGFloat

    static let bones: [(Joint, Joint)] = [
        (.neck, .leftShoulder), (.neck, .rightShoulder),
        (.leftShoulder, .leftElbow), (.leftElbow, .leftWrist),
        (.rightShoulder, .rightElbow), (.rightElbow, .rightWrist),
        (.neck, .root), (.root, .leftHip), (.root, .rightHip),
        (.leftHip, .leftKnee), (.leftKnee, .leftAnkle),
        (.rightHip, .rightKnee), (.rightKnee, .rightAnkle),
    ]
}

/// Front camera -> Vision body pose -> rep counter or stretch tracker. This is the only thing
/// that can silence the alarm. Frames never leave the device and nothing is recorded.
///
/// One sensor stays alive across consecutive camera steps (`switchTo`) so the preview doesn't
/// restart between stretches.
@MainActor
@Observable
final class PoseCameraSensor: NSObject, RoutineSensor {
    enum Mode {
        case reps(Exercise)
        case stretch(Stretch)
    }

    /// What to tell the user about where they are standing.
    enum Guidance: Equatable {
        /// Nobody in view.
        case searching
        /// First camera step only: too close, take a few steps back.
        case stepBack
        /// Framed well; counting starts in a moment.
        case holdStill
        /// Counting.
        case tracking
        /// Mid-step, the joints this exercise needs have left the frame.
        case outOfView
    }

    let captureSession = AVCaptureSession()
    private(set) var guidance: Guidance = .searching
    private(set) var skeleton: BodySkeleton?

    @ObservationIgnored private let processor: FrameProcessor
    @ObservationIgnored private let queue = DispatchQueue(label: "pose-camera")

    /// - Parameter requireFraming: ask the user to step back before counting starts.
    init(mode: Mode, requireFraming: Bool) {
        processor = FrameProcessor(mode: mode, requireFraming: requireFraming)
    }

    func start(emit: @escaping @MainActor (RoutineEvent) -> Void) {
        processor.onResult = { [weak self] guidance, event, skeleton in
            Task { @MainActor in
                self?.guidance = guidance
                self?.skeleton = skeleton
                if let event { emit(event) }
            }
        }
        Task {
            guard await AVCaptureDevice.requestAccess(for: .video) else { return }
            configure()
            queue.async { [captureSession] in
                if !captureSession.isRunning { captureSession.startRunning() }
            }
        }
    }

    /// Moves on to the next camera step without restarting the camera.
    func switchTo(_ mode: Mode) {
        queue.async { [processor] in processor.setMode(mode) }
    }

    func stop() {
        queue.async { [captureSession] in captureSession.stopRunning() }
    }

    private func configure() {
        guard
            captureSession.inputs.isEmpty,
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
            let input = try? AVCaptureDeviceInput(device: device)
        else { return }

        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(processor, queue: queue)

        captureSession.beginConfiguration()
        captureSession.sessionPreset = .vga640x480  // plenty for pose, cheap on battery
        if captureSession.canAddInput(input) { captureSession.addInput(input) }
        if captureSession.canAddOutput(output) { captureSession.addOutput(output) }
        if let connection = output.connection(with: .video) {
            // Deliver upright portrait frames so pose coordinates need no rotation...
            if connection.isVideoRotationAngleSupported(90) { connection.videoRotationAngle = 90 }
            // ...mirrored like the selfie preview, so the stick figure lands on the user.
            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = true
            }
        }
        captureSession.commitConfiguration()
    }
}

/// Runs on the camera queue.
private final class FrameProcessor: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var onResult: ((PoseCameraSensor.Guidance, RoutineEvent?, BodySkeleton?) -> Void)?

    private var mode: PoseCameraSensor.Mode
    private var repCounter: RepCounter?
    private var stretchTracker: StretchTracker?
    private var gate: FramingGate?
    private let request = VNDetectHumanBodyPoseRequest()
    private let minConfidence: Float = 0.3

    init(mode: PoseCameraSensor.Mode, requireFraming: Bool) {
        self.mode = mode
        gate = requireFraming ? FramingGate() : nil
        super.init()
        setMode(mode)
    }

    func setMode(_ mode: PoseCameraSensor.Mode) {
        self.mode = mode
        repCounter = nil
        stretchTracker = nil
        switch mode {
        case .reps(let exercise): repCounter = RepCounter(exercise: exercise)
        case .stretch(let stretch): stretchTracker = StretchTracker(stretch: stretch)
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let aspect = Double(CVPixelBufferGetWidth(pixelBuffer)) / Double(max(CVPixelBufferGetHeight(pixelBuffer), 1))
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        guard
            (try? handler.perform([request])) != nil,
            let body = request.results?.first,
            let joints = try? body.recognizedPoints(.all)
        else {
            onResult?(.searching, nil, nil)
            return
        }

        // Core wants x and y in the same unit (image height), y up: scale x by the aspect.
        func point(_ name: VNHumanBodyPoseObservation.JointName) -> PosePoint {
            guard let joint = joints[name] else { return PosePoint(x: 0, y: 0, confidence: 0) }
            return PosePoint(x: joint.location.x * aspect, y: joint.location.y, confidence: Double(joint.confidence))
        }

        let frame = PoseFrame(
            time: CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds,
            leftWrist: point(.leftWrist), rightWrist: point(.rightWrist),
            leftElbow: point(.leftElbow), rightElbow: point(.rightElbow),
            leftShoulder: point(.leftShoulder), rightShoulder: point(.rightShoulder),
            leftHip: point(.leftHip), rightHip: point(.rightHip),
            leftKnee: point(.leftKnee), rightKnee: point(.rightKnee),
            leftAnkle: point(.leftAnkle), rightAnkle: point(.rightAnkle)
        )
        let skeleton = makeSkeleton(joints, aspect: aspect)

        if var gate, gate.state != .ready {
            let state = gate.ingest(frame)
            self.gate = gate
            switch state {
            case .noBody:
                onResult?(.searching, nil, skeleton)
                return
            case .stepBack:
                onResult?(.stepBack, nil, skeleton)
                return
            case .holdStill:
                onResult?(.holdStill, nil, skeleton)
                return
            case .ready:
                break
            }
        }

        switch mode {
        case .reps(let exercise):
            let result = repCounter?.ingest(frame) ?? .bodyNotVisible
            onResult?(
                result == .bodyNotVisible ? .outOfView : .tracking,
                result == .repCompleted ? .repCounted(exercise) : nil,
                skeleton
            )
        case .stretch(let stretch):
            guard let output = stretchTracker?.ingest(frame) else { return }
            onResult?(
                output.bodyVisible ? .tracking : .outOfView,
                output.credited > 0 ? .stretchHeld(stretch, seconds: output.credited) : nil,
                skeleton
            )
        }
    }

    private func makeSkeleton(
        _ joints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint],
        aspect: Double
    ) -> BodySkeleton {
        let names: [(BodySkeleton.Joint, VNHumanBodyPoseObservation.JointName)] = [
            (.nose, .nose), (.neck, .neck), (.root, .root),
            (.leftShoulder, .leftShoulder), (.rightShoulder, .rightShoulder),
            (.leftElbow, .leftElbow), (.rightElbow, .rightElbow),
            (.leftWrist, .leftWrist), (.rightWrist, .rightWrist),
            (.leftHip, .leftHip), (.rightHip, .rightHip),
            (.leftKnee, .leftKnee), (.rightKnee, .rightKnee),
            (.leftAnkle, .leftAnkle), (.rightAnkle, .rightAnkle),
        ]
        var points: [BodySkeleton.Joint: CGPoint] = [:]
        for (joint, name) in names {
            guard let found = joints[name], found.confidence >= minConfidence else { continue }
            points[joint] = CGPoint(x: found.location.x, y: 1 - found.location.y)
        }
        return BodySkeleton(points: points, imageAspect: CGFloat(aspect))
    }
}
