import Testing
import Foundation
@testable import CineTimer

// Exercises `CineTimerActivityAttributes.ContentState`, the phase/range helper
// shared by the Live Activity and the Home Screen widget.

@Suite("ContentState.init(film:)")
struct ContentStateInitTests {

    @Test func copiesFilmDates() {
        let start = Date(timeIntervalSinceReferenceDate: 0)
        let film = Film(title: "Movie", runningTime: 120, startTime: start, trailerBuffer: 15)
        let opened = start.addingTimeInterval(-600)

        let state = CineTimerActivityAttributes.ContentState(film: film, openedAt: opened)

        #expect(state.openedAt == opened)
        #expect(state.startTime == film.startTime)
        #expect(state.filmStart == film.filmStart)
        #expect(state.filmEnd == film.filmEnd)
    }
}

@Suite("ContentState.phase")
struct ContentStatePhaseTests {

    private let start = Date(timeIntervalSinceReferenceDate: 0)
    private func state(buffer: Int = 15, runtime: Int = 120) -> CineTimerActivityAttributes.ContentState {
        let film = Film(title: "Movie", runningTime: runtime, startTime: start, trailerBuffer: buffer)
        return CineTimerActivityAttributes.ContentState(film: film, openedAt: start.addingTimeInterval(-300))
    }

    @Test func upcomingBeforeStart() {
        #expect(state().phase(at: start.addingTimeInterval(-1)) == .upcoming)
    }

    @Test func trailersAtStart() {
        #expect(state().phase(at: start) == .trailers)
    }

    @Test func playingAtFilmStart() {
        let s = state()
        #expect(s.phase(at: s.filmStart) == .playing)
    }

    @Test func endedAtFilmEnd() {
        let s = state()
        #expect(s.phase(at: s.filmEnd) == .ended)
    }

    @Test func zeroBufferSkipsTrailersPhase() {
        // With no trailer buffer, startTime == filmStart, so the trailers window
        // is empty and showtime lands straight in `.playing`.
        let s = state(buffer: 0)
        #expect(s.phase(at: start) == .playing)
    }
}

@Suite("ContentState ranges")
struct ContentStateRangeTests {

    private let start = Date(timeIntervalSinceReferenceDate: 0)
    private func state(buffer: Int = 15, runtime: Int = 120, opened: TimeInterval = -300) -> CineTimerActivityAttributes.ContentState {
        let film = Film(title: "Movie", runningTime: runtime, startTime: start, trailerBuffer: buffer)
        return CineTimerActivityAttributes.ContentState(film: film, openedAt: start.addingTimeInterval(opened))
    }

    @Test func playingRangeSpansTheFilm() {
        let s = state()
        #expect(s.playingRange == s.filmStart...s.filmEnd)
    }

    @Test func trailersRangeSpansTheBuffer() {
        let s = state()
        #expect(s.trailersRange == s.startTime...s.filmStart)
    }

    @Test func upcomingRangeStartsAtOpenedWhenOpenedFirst() {
        let s = state(opened: -300)
        #expect(s.upcomingRange == s.openedAt...s.startTime)
    }

    @Test func upcomingRangeClampsToStartWhenOpenedAfterStart() {
        // openedAt after startTime would invert the range; the helper clamps the
        // lower bound to startTime so the ClosedRange stays valid.
        let s = state(opened: 600)
        #expect(s.upcomingRange.lowerBound == s.startTime)
        #expect(s.upcomingRange.upperBound == s.startTime)
    }

    @Test func playingRangeNeverInvertsWithZeroRuntime() {
        // A zero-length film would make filmEnd == filmStart; the `max` guard keeps
        // the range valid (degenerate but not crashing).
        let s = state(runtime: 0)
        #expect(s.playingRange.lowerBound <= s.playingRange.upperBound)
    }
}
