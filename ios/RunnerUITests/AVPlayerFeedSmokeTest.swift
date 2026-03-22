import XCTest

final class AVPlayerFeedSmokeTest: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testFeedPlaybackHealthSmoke() {
        let app = XCUIApplication()
        app.launchArguments += ["UITEST_MODE", "PLAYBACK_SMOKE_MODE"]
        app.launch()

        let feedTab = app.buttons["feedTab"].firstMatch
        if feedTab.waitForExistence(timeout: 5) {
            feedTab.tap()
        }

        let feedCollection = app.collectionViews["feedCollectionView"].firstMatch
        let feedTable = app.tables["feedCollectionView"].firstMatch
        let feed: XCUIElement = feedCollection.waitForExistence(timeout: 2) ? feedCollection : feedTable
        XCTAssertTrue(feed.waitForExistence(timeout: 10), "Feed collection/table did not appear.")

        let healthLabel = app.staticTexts["playbackHealthStatusLabel"].firstMatch
        XCTAssertTrue(healthLabel.waitForExistence(timeout: 5), "Playback health label missing.")

        waitForHealthyPlayback(label: healthLabel, timeout: 2.0)
        sleep(1)

        for _ in 0..<5 {
            feed.swipeUp()
            usleep(300_000)
        }

        sleep(2)
        assertNoCriticalErrors(status: healthLabel.label)

        let fullscreenButton = app.buttons["fullscreenButton"].firstMatch
        if fullscreenButton.waitForExistence(timeout: 2) {
            fullscreenButton.tap()
            sleep(2)
            app.swipeDown()
        }

        let muteButton = app.buttons["muteButton"].firstMatch
        if muteButton.waitForExistence(timeout: 2) {
            muteButton.tap()
            usleep(350_000)
            muteButton.tap()
        }

        XCUIDevice.shared.press(.home)
        sleep(1)
        app.activate()

        waitForHealthyPlayback(label: healthLabel, timeout: 3.0)

        assertNoCriticalErrors(status: healthLabel.label)
    }

    private func waitForHealthyPlayback(label: XCUIElement, timeout: TimeInterval) {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let status = label.label
            if !containsCriticalErrors(status) {
                return
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
    }

    private func assertNoCriticalErrors(status: String) {
        let criticalErrors = [
            "FIRST_FRAME_TIMEOUT",
            "READY_WITHOUT_FRAME",
            "VIDEO_FREEZE",
            "PLAYBACK_NOT_STARTED",
            "FULLSCREEN_INTERRUPTION",
            "BACKGROUND_RESUME_FAILURE",
        ]
        for code in criticalErrors {
            XCTAssertFalse(status.contains(code), "Critical playback error captured: \(status)")
        }
    }

    private func containsCriticalErrors(_ status: String) -> Bool {
        [
            "FIRST_FRAME_TIMEOUT",
            "READY_WITHOUT_FRAME",
            "VIDEO_FREEZE",
            "PLAYBACK_NOT_STARTED",
            "FULLSCREEN_INTERRUPTION",
            "BACKGROUND_RESUME_FAILURE",
        ].contains { status.contains($0) }
    }
}
