import SwiftUI
import SwiftData

@main
struct CineTimerApp: App {
    var sharedModelContainer: ModelContainer = {
        do {
            return try ModelContainer(for: Film.self)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
