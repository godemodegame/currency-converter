//
//  AppLaunchUITests.swift
//  CurrencyConverterUITests
//
//  Smoke coverage for launching straight into the converter (onboarding skipped)
//  and the presence of the seeded fixture favorites.
//

import XCTest

final class AppLaunchUITests: UITestCase {
    func testLaunchShowsRatesScreen() {
        launchApp()
        assertExists(ratesNavBar, timeout: launchTimeout, "App should open on the 'Rates' screen")
        assertExists(app.buttons[AXID.Nav.addButton], "Toolbar 'Add' button should be present")
        assertExists(app.buttons[AXID.Nav.removeAdsButton], "Toolbar 'Remove ads' button should be present")
    }

    func testSeededFavoritesAppearInConverter() {
        launchApp()
        assertExists(ratesNavBar, timeout: launchTimeout)

        // Seeded favorites are BTC / EUR / USD — their names render as rows.
        assertExists(app.staticTexts["Bitcoin"], "Seeded BTC favorite should appear")
        assertExists(app.staticTexts["Euro"], "Seeded EUR favorite should appear")
        assertExists(app.staticTexts["US Dollar"], "Seeded USD favorite should appear")

        // The static converter chrome is always present.
        assertExists(app.staticTexts[AXID.Converter.emptyPrompt])
        assertExists(app.textFields[AXID.Converter.amountField])
    }

    func testOnboardingNotShownOnNormalLaunch() {
        launchApp()
        assertExists(ratesNavBar, timeout: launchTimeout)
        XCTAssertFalse(
            app.buttons[AXID.Onboarding.firstContinue].exists,
            "Onboarding must not appear when launched without the onboarding flag"
        )
    }
}
