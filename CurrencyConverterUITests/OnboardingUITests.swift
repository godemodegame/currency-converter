//
//  OnboardingUITests.swift
//  CurrencyConverterUITests
//
//  Walks the full first-launch onboarding flow. Launched with the onboarding
//  flag, the five screens reveal instantly (animations collapsed) and the ATT
//  prompt is skipped, so the flow is deterministic end to end.
//

import XCTest

final class OnboardingUITests: UITestCase {
    func testWalkThroughOnboardingToMainScreen() {
        launchApp(onboarding: true)

        // Screen 1 — "Thank you"
        assertExists(app.staticTexts["Thank you"], timeout: launchTimeout, "Onboarding should start on the welcome screen")
        tapWhenReady(app.buttons[AXID.Onboarding.firstContinue])

        // Screen 2 — "Currency converter!"
        assertExists(app.staticTexts["Currency converter!"])
        tapWhenReady(app.buttons[AXID.Onboarding.secondContinue])

        // Screen 3 — "Crypto support"
        assertExists(app.staticTexts["Crypto support"])
        tapWhenReady(app.buttons[AXID.Onboarding.thirdContinue])

        // Screen 4 — paywall-style finale
        assertExists(app.staticTexts["Well almost free!"])
        tapWhenReady(app.buttons[AXID.Onboarding.maybeLater])

        // Onboarding is dismissed (its content goes away) and the converter,
        // which was behind the sheet, is now interactive.
        assertEventuallyGone(app.staticTexts["Well almost free!"], "Onboarding should be dismissed")
        assertExists(app.buttons[AXID.Nav.addButton], "The converter toolbar should be reachable after onboarding")
    }

    func testOnboardingCannotBeSwipedAway() {
        launchApp(onboarding: true)
        assertExists(app.staticTexts["Thank you"], timeout: launchTimeout)

        // The flow uses `interactiveDismissDisabled()`, so a swipe-down must not
        // dismiss it — the welcome screen and its continue button stay put.
        app.swipeDown()
        assertExists(app.staticTexts["Thank you"], "Onboarding should resist interactive dismissal")
        assertExists(app.buttons[AXID.Onboarding.firstContinue], "Onboarding should still be presented after a swipe")
    }
}
