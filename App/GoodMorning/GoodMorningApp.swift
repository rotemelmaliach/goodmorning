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
                } else {
                    HomeView()
                }
            }
            .environment(session)
            .task {
                WatchLink.shared.activate()
                // Re-plan on every launch so the rolling window of alarms never runs dry.
                await session.rearmAlarms()
            }
        }
    }
}
