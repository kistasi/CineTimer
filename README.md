# CineTimer

An iOS app that turns your cinema visit into a live progress bar. Add a film with its title, runtime, and showtime — CineTimer tracks where you are in the movie in real time, showing percentage seen, time remaining, and expected end time.

## Features

- Add films with title, runtime, showtime, and trailer buffer (default 15 min)
- Live timer updates every second via `TimelineView`
- Four states: upcoming, trailers, playing (with progress bar), ended
- Edit or delete films with swipe actions
- Screen stays awake while the timer is visible

## Requirements

- iOS 17+
- Xcode 16+

## Running the app

Open `CineTimer.xcodeproj` in Xcode and run on a simulator or device.

```bash
xcodebuild -project CineTimer.xcodeproj -scheme CineTimer \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

## Tests

```bash
xcodebuild test -project CineTimer.xcodeproj -scheme CineTimer \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:CineTimerTests
```
