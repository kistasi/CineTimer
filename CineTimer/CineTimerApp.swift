import SwiftUI
import SwiftData

@main
struct CineTimerApp: App {
    let sharedModelContainer: ModelContainer = SharedStore.makeContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
