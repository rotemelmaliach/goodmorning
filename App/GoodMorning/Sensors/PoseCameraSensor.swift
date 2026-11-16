import AVFoundation
import GoodMorningCore
import Observation
import Vision

/// Front camera -> Vision body pose -> rep counter or stretch tracker. This is the only thing
/// that can silence the alarm. Frames never leave the device and nothing is recorded.
@MainActor
@Observable
final class PoseCameraSensor: NSObject, RoutineSensor {
    enum Mode {
        case reps(Exercise)
        case stretch(Stretch)
    }

    let captureSession = AVCaptureSession()
    /// False when the whole body isn't in frame; the UI tells the user to step back.
    private(set) var bodyVisible = false

    @ObservationIgnored private let processor: FrameProcessor
    @ObservationIgnored private let queue = DispatchQueue(label: "pose-camera")

    init(mode: Mode) {
        processor = FrameProcessor(mode: mode)
    }

    func start(emit: @escaping @MainActor (RoutineEvent) -> Void) {
        processor.onResult = { [weak self] bodyVisible, event in
            Task { @MainActor in
                self?.bodyVisible = bodyVisible
                if let event { emit(event) }
            }
        }
        Task {
            guard await AVCaptureDevice.requestAccess(for: .video) else { return }
            configure()
            queue.async { [captureSession] in captureSession.startRunning() }
        }
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
        // Deliver upright portrait frames so pose coordinates need no rotation.
        if let connection = output.connection(with: .video), connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
        captureSession.commitConfiguration()
    }
}

/// Runs on the camera queue.
private final class FrameProcessor: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    /// (whole body visible, event to send to the routine if any)
    var onResult: ((Bool, RoutineEvent?) -> Void)?

    private let mode: PoseCameraSensor.Mode
    private var repCounter: RepCounter?
    private var stretchTracker: StretchTracker?
    private let request = VNDetectHumanBodyPoseRequest()

    init(mode: PoseCameraSensor.Mode) {
        self.mode = mode
        switch mode {
        case .reps(let exercise): repCounter = RepCounter(exercise: exercise)
        case .stretch(let stretch): stretchTracker = StretchTracker(stretch: stretch)
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up)
        guard
            (try? handler.perform([request])) != nil,
            let body = request.results?.first,
            let joints = try? body.recognizedPoints(.all)
        else {
            onResult?(false, nil)
            return
        }

        func point(_ name: VNHumanBodyPoseObservation.JointName) -> PosePoint {
            guard let joint = joints[name] else { return PosePoint(x: 0, y: 0, confidence: 0) }
            return PosePoint(x: joint.location.x, y: joint.location.y, confidence: Double(joint.confidence))
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

        switch mode {
        case .reps(let exercise):
            let result = repCounter?.ingest(frame) ?? .bodyNotVisible
            onResult?(result != .bodyNotVisible, result == .repCompleted ? .repCounted(exercise) : nil)
        case .stretch(let stretch):
            guard let output = stretchTracker?.ingest(frame) else { return }
            onResult?(output.bodyVisible, output.credited > 0 ? .stretchHeld(stretch, seconds: output.credited) : nil)
        }
    }
}
