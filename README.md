# CineTimer

An iOS app that turns your cinema visit into a live progress bar. Add a film with its title, runtime, and showtime — CineTimer tracks where you are in the movie in real time, showing percentage seen, time remaining, and the expected end time.

## Why

In a dark cinema you can't pull up a scrubber to see how far into the film you are or when it'll end. CineTimer recreates that video-player progress experience for the big screen, so you always know how much is left without checking your watch and doing the math against the showtime.

## Features

- Add films with title, runtime, showtime, and a trailer buffer (default 15 min) so the timer starts when the film does, not when the lights dim
- Live timer that updates every second: percentage seen, time remaining, and expected end time
- Four states tracked automatically: upcoming, trailers, playing (with progress bar), and ended
- **Lock Screen & Dynamic Island Live Activity** that keeps ticking on its own — you don't even need to open the app
- **Home Screen widget** (small & medium) showing the most relevant film at a glance
- Edit or delete films with swipe actions
- Screen stays awake while the timer is on screen

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

## Status

Not on the App Store (yet). For now it builds and runs from source.

## A note on the code

This project was written by [Claude Code](https://claude.com/claude-code), Anthropic's CLI coding agent.

## License

Released under the [MIT License](LICENSE).
