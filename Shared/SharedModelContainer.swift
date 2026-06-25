import Foundation
import SwiftData

/// Builds the SwiftData container backing the app and the widget extension.
///
/// The store lives in a shared App Group container so the Home Screen widget
/// (a separate process) can read the same films the app writes.
enum SharedStore {
    /// Must match the App Groups entitlement on both the app and widget targets.
    static let appGroupID = "group.com.kistasi.CineTimer"

    static func makeContainer() -> ModelContainer {
        let configuration = ModelConfiguration(
            groupContainer: .identifier(appGroupID)
        )
        do {
            return try ModelContainer(for: Film.self, configurations: configuration)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
