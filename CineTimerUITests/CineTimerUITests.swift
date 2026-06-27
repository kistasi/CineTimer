import XCTest

/// End-to-end flows over the real app. Each launch passes `-uitesting` so the app
/// uses a throwaway in-memory store (see `CineTimerApp`), making these
/// independent of whatever is in the shared App Group store on the device.
final class CineTimerUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    private func launch(seeded: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uitesting"]
        if seeded { app.launchArguments.append("-seedPlayingFilm") }
        app.launch()
        return app
    }

    @MainActor
    func testEmptyStateWhenNoFilms() throws {
        let app = launch()
        XCTAssertTrue(app.staticTexts["No Films"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["emptyAddFilmButton"].exists)
    }

    @MainActor
    func testAddFilmAppearsInList() throws {
        let app = launch()
        app.buttons["emptyAddFilmButton"].tap()

        let title = app.textFields["titleField"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap()
        title.typeText("Inception")

        let minutes = app.textFields["runtimeMinutesField"]
        minutes.tap()
        minutes.typeText("148")

        app.buttons["saveFilmButton"].tap()

        XCTAssertTrue(app.staticTexts["Inception"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testSeededFilmShowsPlayingBadge() throws {
        let app = launch(seeded: true)
        XCTAssertTrue(app.staticTexts["Test Film"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Playing"].exists)
    }

    @MainActor
    func testSeededPlayingFilmAppearsInRunningSection() throws {
        let app = launch(seeded: true)
        XCTAssertTrue(app.staticTexts["Test Film"].waitForExistence(timeout: 5))
        // A mid-playback film is grouped under the "Running" section header.
        XCTAssertTrue(app.staticTexts["Running"].exists)
    }

    @MainActor
    func testOpeningFilmShowsTimer() throws {
        let app = launch(seeded: true)
        let row = app.staticTexts["Test Film"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()

        // The playing timer screen renders a "Now Playing" chip and a "seen" label.
        XCTAssertTrue(app.staticTexts["seen"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testDeleteFilmReturnsToEmptyState() throws {
        let app = launch(seeded: true)
        XCTAssertTrue(app.staticTexts["Test Film"].waitForExistence(timeout: 5))

        // Target the film's row directly: with section headers present, the first
        // `cell` may be a header rather than the film row.
        app.cells.containing(.staticText, identifier: "Test Film").firstMatch.swipeLeft()
        let delete = app.buttons["Delete"]
        XCTAssertTrue(delete.waitForExistence(timeout: 5))
        delete.tap()

        XCTAssertTrue(app.staticTexts["No Films"].waitForExistence(timeout: 5))
    }
}
