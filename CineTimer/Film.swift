import Foundation
import SwiftData

enum FilmStatus {
    case upcoming
    case trailers
    case playing(progress: Double, elapsed: TimeInterval, remaining: TimeInterval)
    case ended
}

@Model
final class Film {
    var title: String
    var runningTime: Int  // minutes
    var startTime: Date   // when trailers/commercials begin

    var trailerBuffer: Int = 15  // minutes before the film begins

    var filmStart: Date { startTime.addingTimeInterval(Double(trailerBuffer) * 60) }
    var filmEnd: Date   { filmStart.addingTimeInterval(Double(runningTime) * 60) }

    func status(at date: Date = .now) -> FilmStatus {
        if date < startTime {
            return .upcoming
        } else if date < filmStart {
            return .trailers
        } else if date < filmEnd {
            let total = Double(runningTime) * 60
            let elapsed = date.timeIntervalSince(filmStart)
            return .playing(
                progress: elapsed / total,
                elapsed: elapsed,
                remaining: filmEnd.timeIntervalSince(date)
            )
        } else {
            return .ended
        }
    }

    init(title: String, runningTime: Int, startTime: Date, trailerBuffer: Int = 15) {
        self.title = title
        self.runningTime = runningTime
        self.startTime = startTime
        self.trailerBuffer = trailerBuffer
    }
}
