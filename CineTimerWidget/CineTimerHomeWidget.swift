import SwiftData
import SwiftUI
import WidgetKit

// MARK: - Timeline

struct FilmEntry: TimelineEntry {
    let date: Date
    let title: String?
    let state: CineTimerActivityAttributes.ContentState?

    static let placeholder = FilmEntry(
        date: .now,
        title: "Dune: Part Two",
        state: .init(
            openedAt: .now,
            startTime: .now.addingTimeInterval(-300),
            filmStart: .now.addingTimeInterval(600),
            filmEnd: .now.addingTimeInterval(9000)
        )
    )
}

struct FilmProvider: TimelineProvider {
    func placeholder(in context: Context) -> FilmEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (FilmEntry) -> Void) {
        completion(context.isPreview ? .placeholder : currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FilmEntry>) -> Void) {
        let entry = currentEntry()
        // The views self-animate via Text(timerInterval:) / ProgressView(timerInterval:),
        // so within a phase nothing needs pushing. Reload at the next phase boundary
        // (trailers → film → ended, then on to the next film) so the labels/sections flip.
        let now = Date.now
        let reload: Date
        if let state = entry.state {
            reload = [state.startTime, state.filmStart, state.filmEnd]
                .filter { $0 > now }
                .min() ?? now.addingTimeInterval(60 * 60)
        } else {
            reload = now.addingTimeInterval(60 * 60)
        }
        completion(Timeline(entries: [entry], policy: .after(reload)))
    }

    /// Loads the most relevant film: the one currently in progress, otherwise the
    /// soonest upcoming one. Films that have already ended are ignored.
    private func currentEntry() -> FilmEntry {
        let now = Date.now
        let container = SharedStore.makeContainer()
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Film>(sortBy: [SortDescriptor(\.startTime)])

        guard
            let films = try? context.fetch(descriptor),
            let film = films.first(where: { $0.filmEnd > now })
        else {
            return FilmEntry(date: now, title: nil, state: nil)
        }

        let state = CineTimerActivityAttributes.ContentState(film: film, openedAt: now)
        return FilmEntry(date: now, title: film.title, state: state)
    }
}

// MARK: - Widget

struct CineTimerHomeWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CineTimerHomeWidget", provider: FilmProvider()) { entry in
            FilmWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Now Playing")
        .description("The film you're watching, or the next one coming up.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Views

struct FilmWidgetView: View {
    let entry: FilmEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let title = entry.title, let state = entry.state {
            content(title: title, state: state)
        } else {
            emptyState
        }
    }

    @ViewBuilder
    private func content(title: String, state: CineTimerActivityAttributes.ContentState) -> some View {
        let phase = state.phase()
        VStack(alignment: .leading, spacing: family == .systemMedium ? 10 : 6) {
            HStack(spacing: 6) {
                Image(systemName: "film.fill")
                    .foregroundStyle(.green)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }

            Text(phase.label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(phase.color)

            Spacer(minLength: 0)

            switch phase {
            case .playing:
                Text(timerInterval: state.playingRange, countsDown: true)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(.green)
                Text("remaining")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                ProgressView(timerInterval: state.playingRange, countsDown: false) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
                .tint(.green)
            case .upcoming:
                countdown(range: state.upcomingRange, caption: "until trailers", color: .blue)
            case .trailers:
                countdown(range: state.trailersRange, caption: "until film", color: .orange)
            case .ended:
                Text("Enjoy the credits!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if family == .systemMedium {
                Text("ends \(state.filmEnd.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func countdown(range: ClosedRange<Date>, caption: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(timerInterval: range, countsDown: true)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(color)
            Text(caption)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "popcorn")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("No film scheduled")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}
