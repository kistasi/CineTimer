# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

CineTimer is an iOS SwiftUI app that replicates the video-player progress experience for cinema-goers. The user adds a film with a title, runtime, showtime, and trailer buffer (default 15 min). The app then acts as a live timer showing percentage seen, time remaining, and the expected end time.

## Build & run

All build, test, and run operations go through Xcode or `xcodebuild`. There is no package manager (no SPM `Package.swift`, no CocoaPods, no Carthage).

```bash
# Build (simulator)
xcodebuild -project CineTimer.xcodeproj -scheme CineTimer -destination 'platform=iOS Simulator,name=iPhone 17' build

# Run unit tests
xcodebuild test -project CineTimer.xcodeproj -scheme CineTimer -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:CineTimerTests

# Run UI tests
xcodebuild test -project CineTimer.xcodeproj -scheme CineTimer -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:CineTimerUITests
```

Open `CineTimer.xcodeproj` in Xcode to build and run interactively.

## Architecture

### Data model — `Shared/Film.swift`

`Film` is the sole SwiftData `@Model`. It lives in `Shared/` with explicit membership in **both** the app and the widget-extension targets, so the Home Screen widget can fetch the same rows. Stored properties:

| Property        | Type     | Notes                                                                                        |
| --------------- | -------- | -------------------------------------------------------------------------------------------- |
| `title`         | `String` |                                                                                              |
| `runningTime`   | `Int`    | minutes                                                                                      |
| `startTime`     | `Date`   | when trailers/commercials begin                                                              |
| `trailerBuffer` | `Int`    | minutes before film; default `= 15` (inline default enables lightweight SwiftData migration) |

Computed properties (`filmStart`, `filmEnd`) and the `status(at:) -> FilmStatus` method live on the model. `FilmStatus` is a top-level enum with cases `.upcoming`, `.trailers`, `.playing(progress:elapsed:remaining:)`, `.ended`.

### Views

- **`ContentView`** — film list sorted by `startTime`, partitioned into three sections — **Running** (trailers or playing), **Upcoming**, and **Ended** — by `groupedFilms(at:)`, which switches on each film's `status(at:)`. Empty sections are hidden. Each `FilmRow` shows a status badge and, when playing, a live 4pt green progress bar. Uses `TimelineView(.periodic(from:by:1))` for 1-second updates, so the sections re-partition as films transition between states. Swipe-left reveals Delete (red) and Edit (orange) actions.
- **`AddFilmView`** — handles both add and edit via `init(film: Film? = nil)`. Runtime entry has two modes (switchable via segmented control): a plain minutes text field or hour/minute steppers. Trailer buffer is a stepper (0–60 min, step 5).
- **`FilmTimerView`** — the main timer screen. Updates every second via `TimelineView`. Disables the idle timer (`UIApplication.shared.isIdleTimerDisabled`) while visible. Shows contextual content per state: countdown cards when upcoming/in-trailers, a large `%` seen + progress bar + remaining time + end time when playing. Pencil toolbar button opens the edit sheet.

### Data layer

Persistence is handled entirely by SwiftData. The `ModelContainer` is built by `SharedStore.makeContainer()` (in `Shared/SharedModelContainer.swift`, a member of both targets), which points the store at the **App Group** container `group.com.kistasi.CineTimer` via `ModelConfiguration(groupContainer:)`. This shared location is what lets the widget extension (a separate process) read the films. The app creates it in `CineTimerApp` and injects it via `.modelContainer(sharedModelContainer)`; the widget's `FilmProvider` opens its own `ModelContext` against the same store.

The App Group is declared in entitlements on both targets (`CineTimer/CineTimer.entitlements`, `CineTimerWidget/CineTimerWidget.entitlements`), wired via `CODE_SIGN_ENTITLEMENTS`. The group ID must match the `appGroupID` constant in `SharedStore`.

When adding a new stored property to `Film`, assign an inline default value (e.g. `var foo: Int = 0`) so SwiftData can backfill existing rows during lightweight migration without a fatal error.

### Live Activity

The film timer surfaces on the Lock Screen / Dynamic Island via a Live Activity, implemented across three pieces:

- **`Shared/CineTimerActivityAttributes.swift`** — the `ActivityAttributes` type, shared (explicit target membership) between the **CineTimer** app and the **CineTimerWidget** extension. It lives outside both file-system-synchronized groups so it can belong to both targets. `ContentState` carries the key dates (`openedAt`, `startTime`, `filmStart`, `filmEnd`); a `phase(at:)` helper and per-phase `ClosedRange<Date>` properties drive the widget UI.
- **`CineTimer/FilmActivityManager.swift`** — a `@MainActor` singleton (`ObservableObject`) that requests / updates / ends the activity through ActivityKit. Activities are keyed to a film by `String(describing: film.persistentModelID)` stored in the attributes. It exposes `activitiesEnabled` (`ActivityAuthorizationInfo().areActivitiesEnabled`). Two start paths: `start(for:)` is the **explicit** path (bell toggle, timer `onAppear`, edit-restart) and clears suppression; `ensureActivity(for:at:)` is the **auto** path called from `ContentView` while the list is visible — it starts an activity for any film between its `startTime` and `filmEnd` that isn't already live or suppressed, and cleans up (`finish`) once a film ends. `stop(for:)` (the bell turning it off) adds the film to `suppressedFilmIDs` so the auto path won't immediately restart it; `finish(for:)` ends without suppressing (natural end). `FilmTimerView` exposes the bell toolbar toggle, which shows a "Live Activities Are Off" alert pointing to Settings when authorization is off instead of silently no-opping.
  - **Gotcha:** `Activity.activities` does not reflect a just-`request`ed activity synchronously, so `requestActivity` inserts the new ID into `activeFilmIDs` directly rather than relying on `refresh()` — otherwise the bell's running-state never updates.
- **`CineTimerWidget/`** — the widget-extension target (`CineTimerWidgetBundle`), bundling **two** widgets. The Lock Screen and Dynamic Island render self-animating progress/countdowns with `ProgressView(timerInterval:)` and `Text(timerInterval:)`, so they keep ticking without per-second pushes from the app.

### Home Screen widget

`CineTimerWidget/CineTimerHomeWidget.swift` adds a `StaticConfiguration` Home Screen widget (`systemSmall` / `systemMedium`) alongside the Live Activity in `CineTimerWidgetBundle`. Its `FilmProvider` (a `TimelineProvider`) fetches from the shared SwiftData store and picks the most relevant film — the one in progress, else the soonest upcoming, ignoring ended ones. It reuses `CineTimerActivityAttributes.ContentState` for the phase/range helpers, so the same `Text(timerInterval:)` / `ProgressView(timerInterval:)` self-animation drives the widget; the timeline reloads at the next phase boundary (`startTime` / `filmStart` / `filmEnd`) so the labels/sections flip, then advances to the next film.

**Widget refresh:** WidgetKit caches timelines, so the app must call `WidgetCenter.shared.reloadAllTimelines()` whenever films change — wired into `AddFilmView.save()` (add/edit), `ContentView`'s delete swipe, and `FilmTimerView.onAppear` (also exposed as `FilmActivityManager.reloadWidgets()`). Each mutation site also calls `modelContext.save()` so the shared store is flushed before the widget re-reads it. Without these, the widget shows stale data (e.g. "No film scheduled" while a film is playing).

`NSSupportsLiveActivities = YES` is set on the app target via `INFOPLIST_KEY_NSSupportsLiveActivities`. The widget extension uses an explicit `CineTimerWidget/Info.plist` (excluded from its synchronized group via a membership exception) declaring the `com.apple.widgetkit-extension` point. Its bundle ID must stay prefixed by the app's (`com.kistasi.CineTimer.CineTimerWidget`), and the app embeds the `.appex` via an "Embed Foundation Extensions" copy-files phase.

### Testing

- **Unit tests** (`CineTimerTests/`) use the Swift Testing framework (`import Testing`, `@Test`, `#expect`). They cover the pure logic: `Film` (`formatMinutes`, computed dates, `status(at:)`), the shared `CineTimerActivityAttributes.ContentState` (`phase(at:)`, the `ClosedRange<Date>` helpers and their clamp/`max`/`min` guards), `Film` SwiftData round-trips against an in-memory container, and the environment-independent guards of `FilmActivityManager` (the auto-start path's showtime/end checks; the ActivityKit request path itself can't run in the test host).
- **UI tests** (`CineTimerUITests/`) use XCTest / XCUIAutomation and drive real flows (empty state, add, status badge, open timer, delete).
- For SwiftData unit tests, inject an in-memory container: `ModelContainer(for: Film.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))`.
- **Deterministic UI tests:** the app reads launch arguments in `CineTimerApp.init`. `-uitesting` swaps the App Group store for `SharedStore.makeInMemoryContainer()` (a throwaway in-memory store) so tests don't depend on on-device data; adding `-seedPlayingFilm` also inserts one mid-playback film ("Test Film"). Key controls carry `accessibilityIdentifier`s (`addFilmButton`, `emptyAddFilmButton`, `titleField`, `runtimeMinutesField`, `saveFilmButton`).
- **Schemes:** both `CineTimer.xcscheme` and `CineTimerWidget.xcscheme` are **shared** (`xcshareddata/xcschemes/`) and wire `CineTimerTests` + `CineTimerUITests` into their Test action, so `Cmd+U` in Xcode and `xcodebuild test` work from either scheme (the widget scheme uses the app as its test host via `MacroExpansion`). The autogenerated app-extension scheme had an empty Test action, which is what produced the old "Scheme CineTimerWidget is not testable" error.
