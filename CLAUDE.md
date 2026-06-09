# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

CineTimer is an iOS SwiftUI app that replicates the video-player progress experience for cinema-goers. The user adds a film with a title, runtime, showtime, and trailer buffer (default 15 min). The app then acts as a live timer showing percentage seen, time remaining, and the expected end time.

## Build & run

All build, test, and run operations go through Xcode or `xcodebuild`. There is no package manager (no SPM `Package.swift`, no CocoaPods, no Carthage).

```bash
# Build (simulator)
xcodebuild -project CineTimer.xcodeproj -scheme CineTimer -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run unit tests
xcodebuild test -project CineTimer.xcodeproj -scheme CineTimer -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:CineTimerTests

# Run UI tests
xcodebuild test -project CineTimer.xcodeproj -scheme CineTimer -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:CineTimerUITests
```

Open `CineTimer.xcodeproj` in Xcode to build and run interactively.

## Architecture

### Data model — `Film.swift`

`Film` is the sole SwiftData `@Model`. Stored properties:

| Property | Type | Notes |
|---|---|---|
| `title` | `String` | |
| `runningTime` | `Int` | minutes |
| `startTime` | `Date` | when trailers/commercials begin |
| `trailerBuffer` | `Int` | minutes before film; default `= 15` (inline default enables lightweight SwiftData migration) |

Computed properties (`filmStart`, `filmEnd`) and the `status(at:) -> FilmStatus` method live on the model. `FilmStatus` is a top-level enum with cases `.upcoming`, `.trailers`, `.playing(progress:elapsed:remaining:)`, `.ended`.

### Views

- **`ContentView`** — film list sorted by `startTime`. Each `FilmRow` shows a status badge and, when playing, a live 4pt green progress bar. Uses `TimelineView(.periodic(from:by:1))` for 1-second updates. Swipe-left reveals Edit (orange) and Delete (red) actions.
- **`AddFilmView`** — handles both add and edit via `init(film: Film? = nil)`. Runtime entry has two modes (switchable via segmented control): a plain minutes text field or hour/minute steppers. Trailer buffer is a stepper (0–60 min, step 5).
- **`FilmTimerView`** — the main timer screen. Updates every second via `TimelineView`. Disables the idle timer (`UIApplication.shared.isIdleTimerDisabled`) while visible. Shows contextual content per state: countdown cards when upcoming/in-trailers, a large `%` seen + progress bar + remaining time + end time when playing. Pencil toolbar button opens the edit sheet.

### Data layer

Persistence is handled entirely by SwiftData. The `ModelContainer` (on-disk store) is created in `CineTimerApp` and injected via `.modelContainer(sharedModelContainer)`.

When adding a new stored property to `Film`, assign an inline default value (e.g. `var foo: Int = 0`) so SwiftData can backfill existing rows during lightweight migration without a fatal error.

### Testing

- **Unit tests** (`CineTimerTests/`) use the Swift Testing framework (`import Testing`, `@Test`, `#expect`).
- **UI tests** (`CineTimerUITests/`) use XCTest / XCUIAutomation.
- For SwiftData tests, inject an in-memory container: `.modelContainer(for: Film.self, inMemory: true)`.
