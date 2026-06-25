import SwiftUI
import SwiftData

@main
struct CineTimerApp: App {
    let sharedModelContainer: ModelContainer

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-uitesting") {
            let container = SharedStore.makeInMemoryContainer()
            if arguments.contains("-seedPlayingFilm") {
                Self.seedPlayingFilm(into: container)
            }
            sharedModelContainer = container
        } else {
            sharedModelContainer = SharedStore.makeContainer()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }

    /// Inserts one film that is currently mid-playback so UI tests have a stable,
    /// known row to assert against (title "Test Film", "Playing" status).
    @MainActor
    private static func seedPlayingFilm(into container: ModelContainer) {
        // startTime 45 min ago, 15 min trailers → film started 30 min ago, 120 min long → playing.
        let film = Film(
            title: "Test Film",
            runningTime: 120,
            startTime: .now.addingTimeInterval(-45 * 60),
            trailerBuffer: 15
        )
        container.mainContext.insert(film)
        try? container.mainContext.save()
    }
}
