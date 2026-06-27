import ActivityKit
import Combine
import Foundation
import SwiftData
import UIKit
import WidgetKit

/// Starts, updates, and ends the Live Activity for a `Film`.
///
/// The activity carries the key dates and the widget renders live countdowns /
/// progress with `Text(timerInterval:)` and `ProgressView(timerInterval:)`, so
/// it keeps ticking on the Lock Screen without the app pushing per-second updates.
@MainActor
final class FilmActivityManager: ObservableObject {
    static let shared = FilmActivityManager()

    /// IDs of films that currently have a running activity, used to avoid
    /// requesting a duplicate activity for a film that's already live.
    @Published private(set) var activeFilmIDs: Set<String> = []

    private init() {
        refresh()
    }

    private func id(of film: Film) -> String {
        String(describing: film.persistentModelID)
    }

    private func activity(for film: Film) -> Activity<CineTimerActivityAttributes>? {
        let fid = id(of: film)
        return Activity<CineTimerActivityAttributes>.activities.first { $0.attributes.filmID == fid }
    }

    func isRunning(for film: Film) -> Bool {
        activeFilmIDs.contains(id(of: film))
    }

    /// Whether the system currently allows starting Live Activities. `false` when
    /// the user has turned Live Activities off for the app (or globally) in Settings.
    var activitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    /// Reconcile our published state with the activities the system actually has.
    func refresh() {
        activeFilmIDs = Set(
            Activity<CineTimerActivityAttributes>.activities.map { $0.attributes.filmID }
        )
    }

    /// Start the activity for a film (opening the timer, edit-restart). No-op if
    /// the film has already ended or the user has Live Activities disabled.
    func start(for film: Film) {
        requestActivity(for: film)
    }

    /// Auto-start path used while the film list is visible: starts an activity for
    /// a film that has reached showtime and is still running, unless it's already
    /// live. Also cleans up once a film has ended.
    func ensureActivity(for film: Film, at now: Date = .now) {
        let fid = id(of: film)

        guard now < film.filmEnd else {
            if activeFilmIDs.contains(fid) { finish(for: film) }
            return
        }

        guard now >= film.startTime else { return }        // not at showtime yet
        guard !activeFilmIDs.contains(fid) else { return }  // already live
        requestActivity(for: film)
    }

    /// Request (or refresh) the activity. No-op if the film has ended, Live
    /// Activities are disabled, or the app isn't in the foreground.
    private func requestActivity(for film: Film) {
        guard activitiesEnabled else { return }
        guard Date.now < film.filmEnd else { return }
        // ActivityKit rejects `request` with `.visibility` unless the app is in
        // the foreground. The auto-start timer / `onAppear` can fire while
        // backgrounded or mid-transition, so refuse those and let the next
        // foreground sync retry. An already-running activity can still update.
        if activity(for: film) == nil, UIApplication.shared.applicationState == .background {
            return
        }

        if activity(for: film) != nil {
            update(for: film)
            return
        }

        do {
            let activity = try Activity.request(
                attributes: CineTimerActivityAttributes(title: film.title, filmID: id(of: film)),
                content: ActivityContent(state: CineTimerActivityAttributes.ContentState(film: film), staleDate: film.filmEnd)
            )
            // `Activity.activities` doesn't reflect a just-requested activity
            // synchronously, so track the ID directly instead of via `refresh()`.
            activeFilmIDs.insert(activity.attributes.filmID)
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    /// Push fresh dates to a running activity (e.g. after the film is edited).
    func update(for film: Film) {
        guard let activity = activity(for: film) else { return }
        let content = ActivityContent(state: CineTimerActivityAttributes.ContentState(film: film), staleDate: film.filmEnd)
        Task { await activity.update(content) }
    }

    /// Tell the Home Screen widget to re-read the store after films change.
    func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// End and restart so changes to the fixed title are reflected too.
    func restart(for film: Film) {
        Task {
            await endActivities(for: film)
            start(for: film)
        }
    }

    /// End because the film is over. A re-scheduled film can start a fresh
    /// activity later.
    func finish(for film: Film) {
        Task {
            await endActivities(for: film)
        }
    }

    /// Delete a film: tear down its activity, remove the row, flush the store, and
    /// refresh the widget. The single place this sequence lives so the two call
    /// sites (list swipe, timer Trash button) can't drift.
    func delete(_ film: Film, in context: ModelContext) {
        remove(for: film)
        context.delete(film)
        try? context.save()
        reloadWidgets()
    }

    /// End and forget the activity for a film that's being deleted. Captures the
    /// ID synchronously so the async end doesn't touch the deleted model object.
    func remove(for film: Film) {
        let fid = id(of: film)
        activeFilmIDs.remove(fid)
        Task { await endActivities(withID: fid) }
    }

    private func endActivities(for film: Film) async {
        let fid = id(of: film)
        await endActivities(withID: fid)
        activeFilmIDs.remove(fid)
    }

    private func endActivities(withID fid: String) async {
        for activity in Activity<CineTimerActivityAttributes>.activities where activity.attributes.filmID == fid {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
