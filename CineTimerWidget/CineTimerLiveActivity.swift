import ActivityKit
import SwiftUI
import WidgetKit

struct CineTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CineTimerActivityAttributes.self) { context in
            LockScreenLiveActivityView(
                title: context.attributes.title,
                state: context.state
            )
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.4))
            .activitySystemActionForegroundColor(.green)
        } dynamicIsland: { context in
            let state = context.state
            let phase = state.phase()
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.title, systemImage: "film.fill")
                        .font(.headline)
                        .foregroundStyle(.green)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(phase.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(phase.color)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedBottomView(state: state, phase: phase)
                }
            } compactLeading: {
                Image(systemName: "film.fill")
                    .foregroundStyle(.green)
            } compactTrailing: {
                CountdownText(state: state, phase: phase)
                    .foregroundStyle(phase.color)
                    .frame(maxWidth: 58)
            } minimal: {
                Image(systemName: "film.fill")
                    .foregroundStyle(.green)
            }
            .keylineTint(.green)
        }
    }
}

// MARK: - Lock Screen / banner

struct LockScreenLiveActivityView: View {
    let title: String
    let state: CineTimerActivityAttributes.ContentState

    var body: some View {
        let phase = state.phase()
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(title, systemImage: "film.fill")
                    .font(.headline)
                    .foregroundStyle(.green)
                    .lineLimit(1)
                Spacer()
                Text(phase.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(phase.color)
            }

            switch phase {
            case .playing:
                ProgressView(timerInterval: state.playingRange, countsDown: false) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
                .tint(.green)
                HStack(alignment: .firstTextBaseline) {
                    Text(timerInterval: state.playingRange, countsDown: true)
                        .font(.title3.monospacedDigit().weight(.bold))
                        .foregroundStyle(.green)
                    Text("left")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("ends \(state.filmEnd.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case .upcoming:
                countdownRow(range: state.upcomingRange, caption: "until trailers")
            case .trailers:
                countdownRow(range: state.trailersRange, caption: "until film")
            case .ended:
                Text("Enjoy the credits!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func countdownRow(range: ClosedRange<Date>, caption: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(timerInterval: range, countsDown: true)
                .font(.title3.monospacedDigit().weight(.bold))
            Text(caption)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text("ends \(state.filmEnd.formatted(date: .omitted, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Dynamic Island helpers

struct ExpandedBottomView: View {
    let state: CineTimerActivityAttributes.ContentState
    let phase: CineTimerActivityAttributes.ContentState.Phase

    var body: some View {
        switch phase {
        case .playing:
            VStack(spacing: 6) {
                ProgressView(timerInterval: state.playingRange, countsDown: false) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
                .tint(.green)
                HStack(spacing: 4) {
                    Text("ends \(state.filmEnd.formatted(date: .omitted, time: .shortened))")
                    Spacer()
                    Text(timerInterval: state.playingRange, countsDown: true)
                    Text("left")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        case .ended:
            Text("Enjoy the credits!")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .upcoming, .trailers:
            HStack {
                CountdownText(state: state, phase: phase)
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.green)
                Text(phase == .upcoming ? "until trailers" : "until film")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("ends \(state.filmEnd.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// A compact, self-updating countdown appropriate to the current phase.
struct CountdownText: View {
    let state: CineTimerActivityAttributes.ContentState
    let phase: CineTimerActivityAttributes.ContentState.Phase

    var body: some View {
        switch phase {
        case .playing:
            Text(timerInterval: state.playingRange, countsDown: true)
                .monospacedDigit()
        case .trailers:
            Text(timerInterval: state.trailersRange, countsDown: true)
                .monospacedDigit()
        case .upcoming:
            Text(timerInterval: state.upcomingRange, countsDown: true)
                .monospacedDigit()
        case .ended:
            Image(systemName: "checkmark.circle.fill")
        }
    }
}
