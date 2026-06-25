import Testing
import Foundation
import SwiftData
import ActivityKit
@testable import CineTimer

// Covers the environment-independent branches of `FilmActivityManager`. The
// ActivityKit start path can't be exercised in the unit-test host (Live
// Activities aren't authorized there), so these focus on the guards that decide
// *whether* a request is even attempted, which are pure scheduling logic.
//
// Serialized because they read the shared singleton's published state.
@MainActor
@Suite("FilmActivityManager", .serialized)
struct FilmActivityManagerTests {

    private func insertedFilm(
        startOffset: TimeInterval,
        runningTime: Int = 120,
        trailerBuffer: Int = 15
    ) throws -> Film {
        let container = try ModelContainer(
            for: Film.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let film = Film(
            title: "Test",
            runningTime: runningTime,
            startTime: .now.addingTimeInterval(startOffset),
            trailerBuffer: trailerBuffer
        )
        context.insert(film)
        try context.save()
        return film
    }

    @Test func freshFilmIsNotRunning() throws {
        let film = try insertedFilm(startOffset: 3600) // an hour out
        #expect(FilmActivityManager.shared.isRunning(for: film) == false)
    }

    @Test func ensureActivityBeforeShowtimeDoesNotStart() throws {
        // Film is still in the future, so the auto path must not start anything.
        let film = try insertedFilm(startOffset: 3600)
        let manager = FilmActivityManager.shared
        manager.ensureActivity(for: film, at: .now)
        #expect(manager.isRunning(for: film) == false)
    }

    @Test func ensureActivityAfterEndDoesNotStart() throws {
        // Film ended in the past; ensureActivity should clean up / stay off.
        let film = try insertedFilm(startOffset: -10 * 3600)
        let manager = FilmActivityManager.shared
        manager.ensureActivity(for: film, at: .now)
        #expect(manager.isRunning(for: film) == false)
    }

    @Test func activitiesEnabledMatchesSystemAuthorization() {
        #expect(
            FilmActivityManager.shared.activitiesEnabled
            == ActivityAuthorizationInfo().areActivitiesEnabled
        )
    }

    @Test func reloadWidgetsDoesNotCrash() {
        // Smoke check that the WidgetKit hand-off is callable from the host.
        FilmActivityManager.shared.reloadWidgets()
    }
}
