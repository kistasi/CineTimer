import Testing
import Foundation
@testable import CineTimer

// MARK: - formatMinutes

@Suite("Film.formatMinutes")
struct FormatMinutesTests {

    @Test func minutesOnly() {
        #expect(Film.formatMinutes(45) == "45m")
    }

    @Test func exactHour() {
        #expect(Film.formatMinutes(60) == "1h")
    }

    @Test func hoursAndMinutes() {
        #expect(Film.formatMinutes(142) == "2h 22m")
    }

    @Test func zero() {
        #expect(Film.formatMinutes(0) == "0m")
    }
}

// MARK: - Computed dates

@Suite("Film computed dates")
struct FilmDatesTests {

    private func makeFilm(startTime: Date, runningTime: Int = 120, trailerBuffer: Int = 15) -> Film {
        Film(title: "Test", runningTime: runningTime, startTime: startTime, trailerBuffer: trailerBuffer)
    }

    @Test func filmStartIsStartTimePlusBuffer() {
        let start = Date(timeIntervalSinceReferenceDate: 0)
        let film = makeFilm(startTime: start, trailerBuffer: 15)
        #expect(film.filmStart == start.addingTimeInterval(15 * 60))
    }

    @Test func filmEndIsFilmStartPlusRunningTime() {
        let start = Date(timeIntervalSinceReferenceDate: 0)
        let film = makeFilm(startTime: start, runningTime: 90, trailerBuffer: 20)
        let expectedEnd = start.addingTimeInterval((20 + 90) * 60)
        #expect(film.filmEnd == expectedEnd)
    }

    @Test func zeroBufferFilmStartEqualsStartTime() {
        let start = Date(timeIntervalSinceReferenceDate: 1000)
        let film = makeFilm(startTime: start, trailerBuffer: 0)
        #expect(film.filmStart == start)
    }
}

// MARK: - status(at:)

@Suite("Film.status")
struct FilmStatusTests {

    // Reference anchor: startTime = 0, buffer = 15 min, runtime = 120 min
    // upcoming:  date < 0
    // trailers:  0 <= date < 900  (15 * 60)
    // playing:   900 <= date < 8100  (900 + 120 * 60)
    // ended:     date >= 8100

    private let start = Date(timeIntervalSinceReferenceDate: 0)
    private var film: Film {
        Film(title: "Movie", runningTime: 120, startTime: start, trailerBuffer: 15)
    }

    @Test func upcomingBeforeStartTime() {
        let f = film
        let status = f.status(at: start.addingTimeInterval(-1))
        if case .upcoming = status { } else {
            Issue.record("Expected .upcoming, got \(status)")
        }
    }

    @Test func trailersAtExactStartTime() {
        let f = film
        let status = f.status(at: start)
        if case .trailers = status { } else {
            Issue.record("Expected .trailers, got \(status)")
        }
    }

    @Test func trailersInBuffer() {
        let f = film
        let status = f.status(at: start.addingTimeInterval(5 * 60))
        if case .trailers = status { } else {
            Issue.record("Expected .trailers, got \(status)")
        }
    }

    @Test func playingAtFilmStart() {
        let f = film
        let status = f.status(at: f.filmStart)
        if case .playing = status { } else {
            Issue.record("Expected .playing, got \(status)")
        }
    }

    @Test func playingProgressAtHalfway() {
        let f = film
        let halfway = f.filmStart.addingTimeInterval(60 * 60) // 60 min into 120 min film
        let status = f.status(at: halfway)
        if case let .playing(progress, elapsed, remaining) = status {
            #expect(abs(progress - 0.5) < 0.0001)
            #expect(abs(elapsed - 3600) < 0.001)
            #expect(abs(remaining - 3600) < 0.001)
        } else {
            Issue.record("Expected .playing, got \(status)")
        }
    }

    @Test func playingProgressAtStart() {
        let f = film
        let status = f.status(at: f.filmStart)
        if case let .playing(progress, elapsed, _) = status {
            #expect(progress == 0)
            #expect(elapsed == 0)
        } else {
            Issue.record("Expected .playing, got \(status)")
        }
    }

    @Test func endedAtFilmEnd() {
        let f = film
        let status = f.status(at: f.filmEnd)
        if case .ended = status { } else {
            Issue.record("Expected .ended, got \(status)")
        }
    }

    @Test func endedAfterFilmEnd() {
        let f = film
        let status = f.status(at: f.filmEnd.addingTimeInterval(3600))
        if case .ended = status { } else {
            Issue.record("Expected .ended, got \(status)")
        }
    }

    @Test func remainingDecreasesOverTime() {
        let f = film
        let t1 = f.filmStart.addingTimeInterval(30 * 60)
        let t2 = f.filmStart.addingTimeInterval(60 * 60)
        guard case let .playing(_, _, r1) = f.status(at: t1),
              case let .playing(_, _, r2) = f.status(at: t2) else {
            Issue.record("Expected .playing for both")
            return
        }
        #expect(r1 > r2)
    }

    @Test func zeroBufferGoesStraightToPlaying() {
        // No trailers buffer: at showtime the film is already playing.
        let f = Film(title: "Movie", runningTime: 90, startTime: start, trailerBuffer: 0)
        if case .playing = f.status(at: start) { } else {
            Issue.record("Expected .playing at showtime with zero buffer, got \(f.status(at: start))")
        }
    }
}

// MARK: - formattedDuration

@Suite("Film.formattedDuration")
struct FormattedDurationTests {

    @Test func mirrorsFormatMinutes() {
        let f = Film(title: "Movie", runningTime: 142, startTime: .now)
        #expect(f.formattedDuration == Film.formatMinutes(142))
        #expect(f.formattedDuration == "2h 22m")
    }
}
