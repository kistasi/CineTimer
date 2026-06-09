# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

CineTimer is an iOS app built with SwiftUI and SwiftData. It is in early development — the current codebase is essentially the Xcode default template for a SwiftData app, with a `Item` model stub and a placeholder `ContentView`.

## Build & run

All build, test, and run operations go through Xcode or `xcodebuild`. There is no package manager (no SPM `Package.swift`, no CocoaPods, no Carthage) at this time.

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

- **`CineTimerApp.swift`** — app entry point; creates the shared `ModelContainer` with `Item` as the only schema type.
- **`ContentView.swift`** — root SwiftUI view; uses `@Query` to fetch items and `@Environment(\.modelContext)` to insert/delete them.
- **`Item.swift`** — the sole SwiftData `@Model`. Currently only holds a `timestamp: Date`.

### Data layer

Persistence is handled entirely by SwiftData. The `ModelContainer` is configured with `isStoredInMemoryOnly: false` (on-disk store). The container is injected into the SwiftUI environment via `.modelContainer(sharedModelContainer)` in `CineTimerApp`, making `modelContext` available to all views.

### Testing

- **Unit tests** (`CineTimerTests/`) use the Swift Testing framework (`import Testing`, `@Test`, `#expect`).
- **UI tests** (`CineTimerUITests/`) use XCTest / XCUIAutomation.
- For SwiftData tests, inject an in-memory container: `.modelContainer(for: Item.self, inMemory: true)`.
