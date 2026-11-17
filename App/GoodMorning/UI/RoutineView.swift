import AVFoundation
import GoodMorningCore
import SwiftUI

/// Full-screen view for the running routine. There is intentionally no close button.
struct RoutineView: View {
    @Environment(RoutineSession.self) private var session

    var body: some View {
        ZStack {
            Theme.dawn.ignoresSafeArea()
            if let engine = session.engine, let step = engine.currentStep, case .running(let index) = engine.phase {
                VStack(spacing: 18) {
                    header(engine: engine, step: step, index: index)

                    VStack(spacing: 8) {
                        Text(step.title)
                            .font(Theme.title(30))
                            .foregroundStyle(Theme.ink)
                            .multilineTextAlignment(.center)
                        Text(step.instruction)
                            .font(Theme.body)
                            .foregroundStyle(Theme.inkSoft)
                            .multilineTextAlignment(.center)
                    }
                    .id(step.id)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))

                    if let camera = session.camera {
                        cameraCard(camera, engine: engine, step: step)
                    } else {
                        Spacer(minLength: 0)
                        centerpiece(engine: engine, step: step)
                        Spacer(minLength: 0)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .animation(.easeInOut(duration: 0.3), value: step.id)
            }
        }
        .interactiveDismissDisabled()
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }

    // MARK: - Header

    private func header(engine: RoutineEngine, step: RoutineStep, index: Int) -> some View {
        let total = engine.routine.steps.count
        return VStack(spacing: 10) {
            HStack(spacing: 4) {
                ForEach(0..<total, id: \.self) { i in
                    Capsule()
                        .fill(i < index ? Theme.sage : (i == index ? Theme.terracotta : Theme.line))
                        .frame(height: 6)
                }
            }
            HStack {
                Text("Step \(index + 1) of \(total)")
                    .font(Theme.caption.weight(.semibold))
                    .foregroundStyle(Theme.inkSoft)
                Spacer()
                if step.alarmSounding {
                    Label("Alarm on", systemImage: "bell.and.waves.left.and.right.fill")
                        .font(Theme.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Theme.terracotta, in: Capsule())
                        .symbolEffect(.pulse)
                } else {
                    Label("Alarm off", systemImage: "bell.slash.fill")
                        .font(Theme.caption.weight(.semibold))
                        .foregroundStyle(Theme.sage)
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Camera steps

    private func cameraCard(_ camera: PoseCameraSensor, engine: RoutineEngine, step: RoutineStep) -> some View {
        ZStack {
            CameraPreview(session: camera.captureSession)
            SkeletonOverlay(skeleton: camera.skeleton)
            if camera.guidance == .stepBack || camera.guidance == .searching {
                Color.black.opacity(0.25)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(alignment: .top) {
            if let hint = hint(for: camera.guidance) {
                Label(hint.text, systemImage: hint.icon)
                    .font(Theme.body.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(Theme.card.opacity(0.94), in: Capsule())
                    .padding(14)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .overlay(alignment: .bottomTrailing) {
            ProgressRing(progress: engine.progress, lineWidth: 9, tint: Theme.sun) {
                Text(counterText(engine: engine, step: step))
                    .font(Theme.title(30))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: engine.count)
            }
            .frame(width: 104, height: 104)
            .background(.black.opacity(0.35), in: Circle())
            .padding(14)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(camera.guidance == .tracking ? Theme.sage : Theme.peach, lineWidth: 4)
        }
        .shadow(color: Theme.clay.opacity(0.18), radius: 16, y: 8)
        .animation(.easeInOut(duration: 0.25), value: camera.guidance)
        .sensoryFeedback(.impact(weight: .medium), trigger: engine.count)
    }

    private func hint(for guidance: PoseCameraSensor.Guidance) -> (text: String, icon: String)? {
        switch guidance {
        case .searching: ("Stand where the camera can see you", "person.fill.viewfinder")
        case .stepBack: ("Take a few steps back", "arrow.up.backward.and.arrow.down.forward")
        case .holdStill: ("Perfect. Starting…", "checkmark.circle.fill")
        case .outOfView: ("Keep your shoulders and arms in view", "person.fill.viewfinder")
        case .tracking: nil
        }
    }

    private func counterText(engine: RoutineEngine, step: RoutineStep) -> String {
        switch step.goal {
        case .reps(_, let target): "\(max(target - engine.count, 0))"
        case .stretch(_, let seconds): "\(Int((seconds * (1 - engine.progress)).rounded(.up)))s"
        default: ""
        }
    }

    // MARK: - Other steps

    @ViewBuilder
    private func centerpiece(engine: RoutineEngine, step: RoutineStep) -> some View {
        switch step.goal {
        case .timer(let seconds):
            ProgressRing(progress: engine.progress) {
                VStack(spacing: 2) {
                    Text("\(Int((seconds * (1 - engine.progress)).rounded(.up)))")
                        .font(Theme.title(84))
                        .monospacedDigit()
                        .foregroundStyle(Theme.ink)
                        .contentTransition(.numericText())
                    Text("seconds").font(Theme.body).foregroundStyle(Theme.inkSoft)
                }
            }
            .frame(width: 250, height: 250)
        case .walk(let target):
            ProgressRing(progress: engine.progress) {
                Text("\(engine.count) / \(target)")
                    .font(Theme.title(48))
                    .monospacedDigit()
                    .foregroundStyle(Theme.ink)
            }
            .frame(width: 250, height: 250)
        case .confirm:
            VStack(spacing: 28) {
                Image(systemName: icon(for: step))
                    .font(.system(size: 76))
                    .foregroundStyle(Theme.terracotta)
                    .frame(width: 180, height: 180)
                    .background(Theme.peach.opacity(0.45), in: Circle())
                    .symbolEffect(.bounce, value: step.id)
                Button {
                    session.send(.confirmed)
                } label: {
                    Label("Done", systemImage: "checkmark")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        default:
            ProgressRing(progress: engine.progress) { EmptyView() }
                .frame(width: 250, height: 250)
        }
    }

    private func icon(for step: RoutineStep) -> String {
        switch step.id {
        case "lights": "lightbulb.max.fill"
        case "face": "drop.fill"
        case "water": "waterbottle.fill"
        default: "checkmark.circle.fill"
        }
    }
}

/// The white stick figure drawn on top of the user in the selfie preview.
struct SkeletonOverlay: View {
    let skeleton: BodySkeleton?

    var body: some View {
        Canvas { context, size in
            guard let skeleton, size.width > 0, size.height > 0 else { return }
            // Same aspect-fill mapping the preview layer uses.
            let imageWidth = skeleton.imageAspect
            let scale = max(size.width / imageWidth, size.height / 1)
            let shown = CGSize(width: imageWidth * scale, height: scale)
            let origin = CGPoint(x: (size.width - shown.width) / 2, y: (size.height - shown.height) / 2)
            func place(_ point: CGPoint) -> CGPoint {
                CGPoint(x: origin.x + point.x * shown.width, y: origin.y + point.y * shown.height)
            }

            var lines = Path()
            for (a, b) in BodySkeleton.bones {
                guard let from = skeleton.points[a], let to = skeleton.points[b] else { continue }
                lines.move(to: place(from))
                lines.addLine(to: place(to))
            }
            if let nose = skeleton.points[.nose], let neck = skeleton.points[.neck] {
                let center = place(nose)
                let base = place(neck)
                let radius = max(hypot(center.x - base.x, center.y - base.y) * 0.75, 12)
                lines.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
            }

            let round = StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round)
            context.stroke(lines, with: .color(.black.opacity(0.22)), style: StrokeStyle(lineWidth: 11, lineCap: .round, lineJoin: .round))
            context.stroke(lines, with: .color(.white), style: round)

            for point in skeleton.points.values {
                let p = place(point)
                context.fill(Path(ellipseIn: CGRect(x: p.x - 5, y: p.y - 5, width: 10, height: 10)), with: .color(.white))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Shown once the routine is done.
struct CompletionView: View {
    let summary: RoutineSummary
    let streak: Int
    let onDone: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            Theme.dawn.ignoresSafeArea()
            VStack(spacing: 22) {
                Spacer()
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 96))
                    .foregroundStyle(Theme.apricot)
                    .scaleEffect(appeared ? 1 : 0.5)
                    .rotationEffect(.degrees(appeared ? 0 : -40))
                Text("You're up.")
                    .font(Theme.title(44))
                    .foregroundStyle(Theme.ink)
                Text("Routine done in \(Duration.seconds(summary.totalDuration).formatted(.time(pattern: .minuteSecond))).")
                    .font(Theme.body)
                    .foregroundStyle(Theme.inkSoft)
                Label("\(streak) day streak", systemImage: "flame.fill")
                    .font(Theme.body.weight(.semibold))
                    .foregroundStyle(Theme.clay)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Theme.peach.opacity(0.5), in: Capsule())
                Spacer()
                Button("Start the day", action: onDone)
                    .buttonStyle(PrimaryButtonStyle())
            }
            .padding(24)
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.55)) { appeared = true }
        }
        .sensoryFeedback(.success, trigger: appeared)
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
