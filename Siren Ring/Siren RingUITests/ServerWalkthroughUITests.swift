// The app against a real sirenserv with the pretend ring: register, share a code, add the
// contact it finds, and raise the alarm. Runs only when the test is given a server.
import XCTest

final class ServerWalkthroughUITests: XCTestCase {
    let app = XCUIApplication()

    /// setUp launches the app on the pretend ring and the server in SIREN_SERVER, or skips.
    @MainActor
    override func setUpWithError() throws {
        continueAfterFailure = false
        let server = try XCTUnwrap(ProcessInfo.processInfo.environment["SIREN_SERVER"],
                                   "run with TEST_RUNNER_SIREN_SERVER set to a running sirenserv")
        app.launchEnvironment = ["SIREN_ENV": "sim", "SIREN_SERVER": server]
        app.launch()
        let allow = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Allow"]
        if allow.waitForExistence(timeout: 3) { allow.tap() }
    }

    /// shot keeps a picture of the screen in the test results.
    @MainActor
    func shot(_ name: String) {
        let picture = XCTAttachment(screenshot: app.screenshot())
        picture.name = name
        picture.lifetime = .keepAlways
        add(picture)
    }

    /// The ring registers with the server, its share code finds its owner by name, and the alarm
    /// goes out to that contact.
    @MainActor
    func test_register_share_add_and_alarm_against_the_server() {
        app.buttons["A new"].tap()
        if app.buttons["Scan"].waitForExistence(timeout: 2) { app.buttons["Scan"].tap() }
        XCTAssert(app.buttons["Register"].waitForExistence(timeout: 5))
        app.buttons["Register"].tap()
        app.textFields.element(boundBy: 0).tap()
        app.textFields.element(boundBy: 0).typeText("Larry's Ring")
        app.textFields.element(boundBy: 1).tap()
        app.textFields.element(boundBy: 1).typeText("Larry Sam")
        app.buttons["Register Device"].tap()
        XCTAssert(app.staticTexts["My SIREN Ring ready"].waitForExistence(timeout: 10))
        shot("registered")

        app.buttons["Share"].tap()
        app.buttons["Generate Code"].tap()
        let code = app.staticTexts.matching(NSPredicate(format: "label MATCHES '[0-9]{6}'")).firstMatch
        XCTAssert(code.waitForExistence(timeout: 10))
        let shared = code.label
        shot("share code")
        app.buttons["Done"].tap()

        app.buttons["Add"].tap()
        app.buttons["SIREN App Code"].tap()
        app.textFields["000000"].tap()
        app.textFields["000000"].typeText(shared)
        app.buttons["Add Contact"].tap()
        XCTAssert(app.staticTexts["Larry Sam"].waitForExistence(timeout: 10))
        shot("contact added")

        app.buttons["Press"].tap()
        XCTAssert(app.staticTexts["EMERGENCY ACTIVE"].waitForExistence(timeout: 5))
        shot("alarm")
    }
}
