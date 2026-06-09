import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Film.startTime, order: .forward)]) private var films: [Film]
    @State private var showingAddFilm = false
    @State private var filmToEdit: Film?

    var body: some View {
        NavigationStack {
            Group {
                if films.isEmpty {
                    emptyState
                } else {
                    filmList
                }
            }
            .navigationTitle("CineTimer")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAddFilm = true } label: {
                        Label("Add Film", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddFilm) {
                AddFilmView()
            }
            .sheet(item: $filmToEdit) { film in
                AddFilmView(film: film)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Films", systemImage: "film.stack")
        } description: {
            Text("Tap + to add a film before heading to the cinema.")
        } actions: {
            Button("Add Film") { showingAddFilm = true }
                .buttonStyle(.borderedProminent)
        }
    }

    private var filmList: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            List {
                ForEach(films) { film in
                    NavigationLink(destination: FilmTimerView(film: film)) {
                        FilmRow(film: film, now: context.date)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { modelContext.delete(film) } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button { filmToEdit = film } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.orange)
                    }
                }
            }
        }
    }

}

private struct FilmRow: View {
    let film: Film
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(film.title)
                    .font(.headline)
                Spacer()
                statusBadge
            }
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
            if case .playing(let progress, _, _) = film.status(at: now) {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.green.opacity(0.2)).frame(height: 4)
                        Capsule().fill(.green)
                            .frame(width: proxy.size.width * CGFloat(progress), height: 4)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(.vertical, 2)
    }

    private var subtitle: String {
        let start = film.startTime.formatted(date: .omitted, time: .shortened)
        let end = film.filmEnd.formatted(date: .omitted, time: .shortened)
        let h = film.runningTime / 60
        let m = film.runningTime % 60
        let duration = h > 0 ? (m > 0 ? "\(h)h \(m)m" : "\(h)h") : "\(m)m"
        return "\(start) · \(duration) · ends \(end)"
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch film.status(at: now) {
        case .upcoming: badge("Upcoming", .blue)
        case .trailers:  badge("Trailers", .orange)
        case .playing:   badge("Playing", .green)
        case .ended:     badge("Ended", .secondary)
        }
    }

    private func badge(_ label: String, _ color: Color) -> some View {
        Text(label)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
