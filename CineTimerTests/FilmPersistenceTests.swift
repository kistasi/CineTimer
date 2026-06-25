import Testing
import Foundation
import SwiftData
@testable import CineTimer

// Round-trips `Film` through a real (in-memory) SwiftData container to cover the
// model's persistence: insert, fetch ordering, update, delete, and the
// lightweight-migration default for `trailerBuffer`.

@MainActor
@Suite("Film persistence")
struct FilmPersistenceTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Film.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    @Test func insertAndFetch() throws {
        let context = try makeContext()
        context.insert(Film(title: "Dune", runningTime: 166, startTime: .now))

        let films = try context.fetch(FetchDescriptor<Film>())
        #expect(films.count == 1)
        #expect(films.first?.title == "Dune")
        #expect(films.first?.runningTime == 166)
    }

    @Test func fetchSortedByStartTime() throws {
        let context = try makeContext()
        let base = Date(timeIntervalSinceReferenceDate: 0)
        context.insert(Film(title: "Late", runningTime: 90, startTime: base.addingTimeInterval(7200)))
        context.insert(Film(title: "Early", runningTime: 90, startTime: base))
        context.insert(Film(title: "Middle", runningTime: 90, startTime: base.addingTimeInterval(3600)))

        let descriptor = FetchDescriptor<Film>(sortBy: [SortDescriptor(\.startTime)])
        let titles = try context.fetch(descriptor).map(\.title)
        #expect(titles == ["Early", "Middle", "Late"])
    }

    @Test func updatePersists() throws {
        let context = try makeContext()
        let film = Film(title: "Old", runningTime: 100, startTime: .now)
        context.insert(film)

        film.title = "New"
        film.runningTime = 110
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Film>()).first
        #expect(fetched?.title == "New")
        #expect(fetched?.runningTime == 110)
    }

    @Test func deleteRemovesRow() throws {
        let context = try makeContext()
        let film = Film(title: "Doomed", runningTime: 90, startTime: .now)
        context.insert(film)
        context.delete(film)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<Film>()).isEmpty)
    }

    @Test func trailerBufferDefaultsToFifteen() throws {
        let context = try makeContext()
        // Mirrors the inline default that lets SwiftData backfill existing rows.
        let film = Film(title: "Default", runningTime: 90, startTime: .now)
        context.insert(film)

        let fetched = try context.fetch(FetchDescriptor<Film>()).first
        #expect(fetched?.trailerBuffer == 15)
    }
}
