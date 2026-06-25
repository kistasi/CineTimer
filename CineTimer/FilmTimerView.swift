import Combine
import SwiftUI

struct FilmTimerView: View {
    let film: Film
    @State private var showingEdit = false
    @State private var showingActivitiesDisabledAlert = false
    @ObservedObject private var activities = FilmActivityManager.shared

    private let endCheck = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            timerContent(at: context.date)
        }
        .navigationTitle(film.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                let running = activities.isRunning(for: film)
                Button {
                    if running {
                        activities.stop(for: film)
                    } else if activities.activitiesEnabled {
                        activities.start(for: film)
                    } else {
                        showingActivitiesDisabledAlert = true
                    }
                } label: {
                    Label(
                        running ? "Stop Live Activity" : "Start Live Activity",
                        systemImage: running ? "bell.slash" : "bell"
                    )
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button { showingEdit = true } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
        }
        .sheet(isPresented: $showingEdit, onDismiss: { activities.restart(for: film) }) {
            AddFilmView(film: film)
        }
        .alert("Live Activities Are Off", isPresented: $showingActivitiesDisabledAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Turn on Live Activities for CineTimer in Settings to show the timer on the Lock Screen and Dynamic Island.")
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            activities.start(for: film)
            activities.reloadWidgets()
        }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        .onReceive(endCheck) { _ in
            if Date.now >= film.filmEnd { activities.finish(for: film) }
        }
    }

    private func timerContent(at now: Date) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                statusContent(for: film.status(at: now), now: now)
            }
            .padding()
        }
    }

    @ViewBuilder
    private func statusContent(for status: FilmStatus, now: Date) -> some View {
        switch status {
        case .upcoming:
            upcomingContent(at: now)
        case .trailers:
            trailersContent(at: now)
        case .playing(let progress, let elapsed, let remaining):
            playingContent(progress: progress, elapsed: elapsed, remaining: remaining)
        case .ended:
            endedContent()
        }
    }

    @ViewBuilder
    private func upcomingContent(at now: Date) -> some View {
        statusChip("Upcoming", icon: "clock", color: .blue)
        infoCard(
            value: formatInterval(film.startTime.timeIntervalSince(now)),
            label: "until trailers",
            icon: "film"
        )
        infoCard(
            value: film.filmStart.formatted(date: .omitted, time: .shortened),
            label: "film starts at",
            icon: "play.fill"
        )
        infoCard(
            value: film.filmEnd.formatted(date: .omitted, time: .shortened),
            label: "ends at",
            icon: "stop.fill"
        )
    }

    @ViewBuilder
    private func trailersContent(at now: Date) -> some View {
        statusChip("Trailers", icon: "film.fill", color: .orange)
        infoCard(
            value: formatInterval(film.filmStart.timeIntervalSince(now)),
            label: "until film starts",
            icon: "timer"
        )
        infoCard(
            value: film.filmEnd.formatted(date: .omitted, time: .shortened),
            label: "ends at",
            icon: "stop.fill"
        )
    }

    @ViewBuilder
    private func playingContent(progress: Double, elapsed: TimeInterval, remaining: TimeInterval) -> some View {
        statusChip("Now Playing", icon: "play.fill", color: .green)
        progressCard(progress: progress, elapsed: elapsed)
        infoCard(
            value: formatInterval(remaining),
            label: "remaining",
            icon: "hourglass"
        )
        infoCard(
            value: film.filmEnd.formatted(date: .omitted, time: .shortened),
            label: "ends at",
            icon: "stop.fill"
        )
    }

    @ViewBuilder
    private func endedContent() -> some View {
        statusChip("Ended", icon: "checkmark.circle.fill", color: .secondary)
        Text("Enjoy the credits!")
            .font(.title3)
            .foregroundStyle(.secondary)
            .padding(.top, 8)
    }

    private func statusChip(_ label: String, icon: String, color: Color) -> some View {
        Label(label, systemImage: icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private func progressCard(progress: Double, elapsed: TimeInterval) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(.green)
                Text("seen")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.green.opacity(0.2))
                        .frame(height: 10)
                    Capsule()
                        .fill(.green)
                        .frame(width: proxy.size.width * CGFloat(progress), height: 10)
                }
            }
            .frame(height: 10)
            Text(formatInterval(elapsed) + " elapsed")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func infoCard(value: String, label: String, icon: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func formatInterval(_ interval: TimeInterval) -> String {
        let secs = max(0, Int(interval))
        let h = secs / 3600
        let m = (secs % 3600) / 60
        let s = secs % 60
        if h > 0 { return String(format: "%dh %02dm", h, m) }
        if m > 0 { return String(format: "%dm %02ds", m, s) }
        return "\(s)s"
    }
}
