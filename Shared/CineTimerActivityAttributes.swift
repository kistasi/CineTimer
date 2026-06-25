import ActivityKit
import Foundation

/// Shared between the CineTimer app (which starts/updates the activity) and the
/// widget extension (which renders it on the Lock Screen / Dynamic Island).
struct CineTimerActivityAttributes: ActivityAttributes {
    /// The parts of the film that can change while the activity is live.
    public struct ContentState: Codable, Hashable {
        /// When the activity was started — used as the lower bound for the
        /// "until trailers" countdown so it reads sensibly.
        var openedAt: Date
        /// When trailers/commercials begin.
        var startTime: Date
        /// When the feature itself starts.
        var filmStart: Date
        /// When the film ends.
        var filmEnd: Date
    }

    /// Fixed for the lifetime of the activity.
    var title: String
    /// Identifies which `Film` this activity belongs to.
    var filmID: String
}

extension CineTimerActivityAttributes.ContentState {
    enum Phase: String {
        case upcoming, trailers, playing, ended
    }

    func phase(at date: Date = .now) -> Phase {
        if date < startTime { return .upcoming }
        if date < filmStart { return .trailers }
        if date < filmEnd { return .playing }
        return .ended
    }

    /// Time range used to drive the self-animating progress bar while playing.
    var playingRange: ClosedRange<Date> { filmStart...max(filmStart, filmEnd) }
    /// Countdown range until the film proper starts (during trailers).
    var trailersRange: ClosedRange<Date> { startTime...max(startTime, filmStart) }
    /// Countdown range until trailers begin (while upcoming).
    var upcomingRange: ClosedRange<Date> { min(openedAt, startTime)...startTime }
}
