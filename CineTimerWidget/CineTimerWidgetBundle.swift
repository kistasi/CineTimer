import SwiftUI
import WidgetKit

@main
struct CineTimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        CineTimerLiveActivity()
        CineTimerHomeWidget()
    }
}
