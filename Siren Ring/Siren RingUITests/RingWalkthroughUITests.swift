// The app walked through on screen with the pretend ring, tapping what a person would tap.
import XCTest

final class RingWalkthroughUITests: XCTestCase {
    let app = XCUIApplication()

    /// setUp launches the app on the pretend ring and lets it send notifications.
    @MainActor
    override func setUp() {
        continueAfterFailure = false
        app.launchEnvironment["SIREN_ENV"] = "sim"
        app.launch()
        let allow = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Allow"]
        if allow.waitForExistence(timeout: 3) { allow.tap() }
    }

    /// connectRingA brings ring A in range and waits until it is the app's ring.
    @MainActor
    func connectRingA() {
        app.buttons["A registered"].tap()
        if app.buttons["Scan"].exists { app.buttons["Scan"].tap() }
        if app.buttons["Done"].waitForExistence(timeout: 2) { app.buttons["Done"].tap() }
        XCTAssert(app.staticTexts["My SIREN Ring ready"].waitForExistence(timeout: 5))
    }

    /// shot keeps a picture of the screen in the test results.
    @MainActor
    func shot(_ name: String) {
        let picture = XCTAttachment(screenshot: app.screenshot())
        picture.name = name
        picture.lifetime = .keepAlways
        add(picture)
    }

    /// On a fresh install, a ring that is already registered pairs itself and the card slides up.
    @MainActor
    func test_card_slides_up_when_a_registered_ring_pairs_itself() throws {
        let paired = app.staticTexts["Scanning for SIREN Rings..."].waitForExistence(timeout: 2)
        try XCTSkipIf(paired, "needs a fresh install with no pairing")
        app.buttons["A registered"].tap()
        app.buttons["Scan"].tap()
        XCTAssert(app.staticTexts["SIREN Ring Connected"].waitForExistence(timeout: 5))
        shot("card")
    }

    /// A stranger ring is turned away, its press does nothing, and the app goes back to ours.
    @MainActor
    func test_a_stranger_ring_is_turned_away_and_its_press_does_nothing() {
        connectRingA()
        app.buttons["B registered"].tap()
        XCTAssert(app.staticTexts["Disconnected"].waitForExistence(timeout: 5))
        app.buttons["Press"].tap()
        shot("stranger pressed")
        XCTAssertFalse(app.staticTexts["EMERGENCY ACTIVE"].waitForExistence(timeout: 2))
        app.buttons["A registered"].tap()
        XCTAssert(app.staticTexts["My SIREN Ring ready"].waitForExistence(timeout: 5))
    }

    /// A ring with no id yet offers no Register.
    @MainActor
    func test_a_ring_not_ready_offers_no_register() {
        connectRingA()
        app.buttons["Not ready"].tap()
        XCTAssert(app.staticTexts["SIREN Ring not ready"].waitForExistence(timeout: 5))
        shot("not ready")
        XCTAssertFalse(app.buttons["Register"].exists)
        XCTAssertFalse(app.buttons["Deregister"].exists)
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "label CONTAINS 'Manual Emergency'")).firstMatch.exists)
    }

    /// Walking the ring away shows it gone, and bringing it back reconnects with no tap.
    @MainActor
    func test_walking_away_shows_disconnected_and_coming_back_reconnects() {
        connectRingA()
        app.buttons["Walk away"].tap()
        XCTAssert(app.staticTexts["Disconnected"].waitForExistence(timeout: 5))
        app.buttons["Come back"].tap()
        XCTAssert(app.staticTexts["My SIREN Ring ready"].waitForExistence(timeout: 5))
    }

    /// A new ring registered through the form can be pressed, released and walked away.
    @MainActor
    func test_a_registered_new_ring_presses_and_walks_away() {
        app.buttons["A new"].tap()
        if app.buttons["Scan"].exists { app.buttons["Scan"].tap() }
        app.buttons["Register"].tap()
        app.textFields.element(boundBy: 0).tap()
        app.textFields.element(boundBy: 0).typeText("Ring")
        app.textFields.element(boundBy: 1).tap()
        app.textFields.element(boundBy: 1).typeText("Me")
        app.buttons["Register Device"].tap()
        XCTAssert(app.staticTexts["My SIREN Ring ready"].waitForExistence(timeout: 5))
        app.buttons["Press"].tap()
        XCTAssert(app.staticTexts["EMERGENCY ACTIVE"].waitForExistence(timeout: 5))
        shot("emergency active")
        app.buttons["Release"].tap()
        app.buttons["Walk away"].tap()
        XCTAssert(app.staticTexts["Disconnected"].waitForExistence(timeout: 5))
    }

    /// Sound Ring makes the ring sound, and its alarm comes back like a press on the ring.
    @MainActor
    func test_sound_ring_raises_the_emergency_from_the_ring() {
        connectRingA()
        app.buttons["Sound Ring"].tap()
        XCTAssert(app.staticTexts["EMERGENCY ACTIVE"].waitForExistence(timeout: 5))
        shot("sounded from the app")
    }

    /// The top left button deregisters the ring, which offers Register again.
    @MainActor
    func test_deregister_offers_register_again() {
        connectRingA()
        app.buttons["Deregister"].tap()
        XCTAssert(app.buttons["Register"].waitForExistence(timeout: 5))
    }

    /// With no ring connected there is nothing to deregister, so the button is not there.
    @MainActor
    func test_deregister_is_hidden_with_no_ring_connected() {
        connectRingA()
        app.buttons["Walk away"].tap()
        XCTAssert(app.staticTexts["Disconnected"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Deregister"].exists)
    }
}
