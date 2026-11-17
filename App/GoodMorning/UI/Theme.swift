import SwiftUI

/// The app's look: a warm dawn palette (cream, peach, terracotta, sage) and the shared
/// building blocks. The same tokens are mirrored in docs/ui-lab/index.html, so a change
/// tried in the lab can be copied here by name.
enum Theme {
    static let canvas = Color(hex: 0xFFF4EA)      // page background, warm cream
    static let card = Color(hex: 0xFFFBF6)        // raised surfaces
    static let peach = Color(hex: 0xFFD0A8)       // soft highlight
    static let apricot = Color(hex: 0xF0A878)     // gradient warm end
    static let terracotta = Color(hex: 0xC56B4B)  // primary actions
    static let clay = Color(hex: 0x9E4A33)        // pressed / strong accent
    static let sage = Color(hex: 0x7A8C6E)        // success, calm secondary
    static let sageSoft = Color(hex: 0xDDE5D3)    // sage tint for fills
    static let sun = Color(hex: 0xF5DF98)         // gentle yellow glow
    static let ink = Color(hex: 0x3F2A20)         // primary text, deep walnut
    static let inkSoft = Color(hex: 0x806A5B)     // secondary text
    static let line = Color(hex: 0xF0DCCB)        // hairlines and empty tracks

    /// Sunrise wash behind every screen.
    static let dawn = LinearGradient(
        colors: [Color(hex: 0xFFE2C6), Color(hex: 0xFFF4EA), Color(hex: 0xFFF4EA)],
        startPoint: .top,
        endPoint: .bottom
    )
    /// The hero card and primary buttons.
    static let glow = LinearGradient(
        colors: [Color(hex: 0xF2B184), Color(hex: 0xD9805C), Color(hex: 0xC56B4B)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let corner: CGFloat = 24

    // Motion. One strong ease-out curve everywhere; UI stays under 300 ms and nothing bounces
    // except the once-a-day celebration. Presses shrink to 0.97: enough to feel, not to see.
    static let pressScale: CGFloat = 0.97
    static func easeOut(_ duration: Double = 0.2) -> Animation {
        .timingCurve(0.23, 1, 0.32, 1, duration: duration)
    }
    /// For things that move across the screen rather than enter or leave.
    static func easeInOut(_ duration: Double = 0.25) -> Animation {
        .timingCurve(0.77, 0, 0.175, 1, duration: duration)
    }
    static let press = easeOut(0.15)

    static func title(_ size: CGFloat) -> Font { .system(size: size, weight: .bold, design: .rounded) }
    static let heading = Font.system(.headline, design: .rounded).weight(.semibold)
    static let body = Font.system(.body, design: .rounded)
    static let caption = Font.system(.footnote, design: .rounded)
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// A titled, rounded surface.
struct Card<Content: View>: View {
    var title: String?
    var icon: String?
    @ViewBuilder var content: Content

    init(_ title: String? = nil, icon: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let title {
                HStack(spacing: 8) {
                    if let icon {
                        Image(systemName: icon).foregroundStyle(Theme.terracotta)
                    }
                    Text(title).font(Theme.heading).foregroundStyle(Theme.ink)
                }
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
        .shadow(color: Theme.clay.opacity(0.08), radius: 14, y: 6)
    }
}

/// Every tappable thing squeezes slightly under the finger and gives a light tap.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? Theme.pressScale : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(Theme.press, value: configuration.isPressed)
            .sensoryFeedback(.impact(weight: .light), trigger: configuration.isPressed) { _, pressed in pressed }
    }
}

/// The big call-to-action.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.title3, design: .rounded).weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Theme.glow, in: Capsule())
            .shadow(color: Theme.terracotta.opacity(configuration.isPressed ? 0.15 : 0.35), radius: 12, y: 6)
            .scaleEffect(configuration.isPressed ? Theme.pressScale : 1)
            .animation(Theme.press, value: configuration.isPressed)
            .sensoryFeedback(.impact(weight: .medium), trigger: configuration.isPressed) { _, pressed in pressed }
    }
}

/// A quieter button: tinted outline pill.
struct SoftButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .foregroundStyle(Theme.clay)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Theme.peach.opacity(configuration.isPressed ? 0.7 : 0.4), in: Capsule())
            .scaleEffect(configuration.isPressed ? Theme.pressScale : 1)
            .animation(Theme.press, value: configuration.isPressed)
            .sensoryFeedback(.impact(weight: .light), trigger: configuration.isPressed) { _, pressed in pressed }
    }
}

/// A circular progress ring with something in the middle.
struct ProgressRing<Label: View>: View {
    var progress: Double
    var lineWidth: CGFloat = 14
    var tint: Color = Theme.terracotta
    @ViewBuilder var label: Label

    var body: some View {
        ZStack {
            Circle().stroke(Theme.line, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(progress, 1)))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                // Progress is constant motion, so it moves linearly and briefly.
                .animation(.linear(duration: 0.25), value: progress)
            label
        }
    }
}

/// Staggered entrance: each item fades up a few points, slightly after the one before it.
/// Delays are short and uneven so the cascade reads as one movement. With Reduce Motion on,
/// items only fade.
struct Entrance: ViewModifier {
    let index: Int
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let delays: [Double] = [0, 0.05, 0.09, 0.12, 0.145, 0.165, 0.18]

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : 8)
            .onAppear {
                let delay = Self.delays[min(index, Self.delays.count - 1)]
                withAnimation(Theme.easeOut(0.3).delay(delay)) { shown = true }
            }
    }
}

extension View {
    func entrance(_ index: Int) -> some View { modifier(Entrance(index: index)) }
}
