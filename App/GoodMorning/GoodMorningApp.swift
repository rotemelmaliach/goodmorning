import GoodMorningCore
import SwiftUI

@main
struct GoodMorningApp: App {
    @State private var session = RoutineSession.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if session.isActive {
                    RoutineView()
                } else if let summary = session.finished {
                    CompletionView(summary: summary, streak: Store.streak) { session.finished = nil }
                } else {
                    HomeView()
                }
            }
            .environment(session)
            .preferredColorScheme(.light)
            .tint(Theme.terracotta)
            .animation(Theme.easeOut(0.3), value: session.isActive)
            .task {
                WatchLink.shared.activate()
                // Re-plan on every launch so the rolling window of alarms never runs dry.
                await session.rearmAlarms()
            }
        }
    }
}
