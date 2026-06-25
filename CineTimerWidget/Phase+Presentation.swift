import SwiftUI

extension CineTimerActivityAttributes.ContentState.Phase {
    var label: String {
        switch self {
        case .upcoming: "Upcoming"
        case .trailers: "Trailers"
        case .playing:  "Now Playing"
        case .ended:    "Ended"
        }
    }

    var color: Color {
        switch self {
        case .upcoming: .blue
        case .trailers: .orange
        case .playing:  .green
        case .ended:    .secondary
        }
    }
}
