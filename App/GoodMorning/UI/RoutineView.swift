import AVFoundation
import GoodMorningCore
import SwiftUI

/// Full-screen view for the running routine. There is intentionally no close button.
struct RoutineView: View {
    @Environment(RoutineSession.self) private var session

    var body: some View {
        if let engine = session.engine, let step = engine.currentStep {
            VStack(spacing: 24) {
                Text(step.title).font(.largeTitle.bold())
                Text(step.instruction).font(.title3).multilineTextAlignment(.center)

                if let camera = session.camera {
                    CameraPreview(session: camera.captureSession)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .overlay(alignment: .bottom) {
                            if !camera.bodyVisible {
                                Text("Step back until your whole body is visible")
                                    .padding(8)
                                    .background(.thinMaterial, in: Capsule())
                                    .padding()
                            }
                        }
                }

                switch step.goal {
                case .walk(let target), .reps(_, let target):
                    Text("\(engine.count) / \(target)")
                        .font(.system(size: 72, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                case .stretch(_, let seconds):
                    Text("\(Int((seconds * (1 - engine.progress)).rounded(.up))) s")
                        .font(.system(size: 72, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                case .confirm:
                    Button("Done") { session.send(.confirmed) }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                default:
                    EmptyView()
                }

                ProgressView(value: engine.progress)
            }
            .padding()
            .interactiveDismissDisabled()
            .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
            .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}
