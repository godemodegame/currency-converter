//
//  CurrencyListUITests.swift
//  CurrencyConverterUITests
//
//  Covers the "Add" → Currencies List flow: navigation, segment filtering,
//  search, favorite toggling (verified through the Favorite segment), and back
//  navigation. Backed by the fixture list (4 fiat: USD/EUR/GBP/JPY, 3 crypto:
//  BTC/ETH/SOL) with BTC/EUR/USD pre-seeded as favorites.
//

import XCTest

final class CurrencyListUITests: UITestCase {
    private var segmentedControl: XCUIElement {
        app.segmentedControls[AXID.List.segmentedControl]
    }

    /// Launches, opens the currencies list, and returns once it is on screen.
    private func openCurrencyList() {
        launchApp()
        assertExists(ratesNavBar, timeout: launchTimeout)
        tapWhenReady(app.buttons[AXID.Nav.addButton])
        assertExists(app.navigationBars["Currencies List"], "Tapping 'Add' should push the Currencies List")
        assertExists(segmentedControl)
    }

    private func selectSegment(_ title: String) {
        let button = segmentedControl.buttons[title]
        assertExists(button)
        button.tap()
    }

    private func revealSearchField() -> XCUIElement {
        let field = app.searchFields.firstMatch
        if !field.waitForExistence(timeout: defaultTimeout) || !field.isHittable {
            // Pull down on the list (not the whole app, which could land on the
            // segmented control) to reveal a search bar tucked under the nav bar.
            app.collectionViews.firstMatch.swipeDown()
        }
        _ = waitForHittable(field, timeout: defaultTimeout)
        return field
    }

    func testNavigateToCurrencyList() {
        openCurrencyList()
        // All four segments should be present.
        for title in ["Favorite", "All", "Cash", "Crypto"] {
            assertExists(segmentedControl.buttons[title], "Segment '\(title)' should exist")
        }
    }

    func testSegmentsFilterByType() {
        openCurrencyList()

        selectSegment("All")
        assertExists(app.staticTexts["US Dollar"], "All segment should list fiat")
        assertExists(app.staticTexts["Bitcoin"], "All segment should list crypto")

        selectSegment("Cash")
        assertExists(app.staticTexts["US Dollar"], "Cash segment should keep fiat")
        assertEventuallyGone(app.staticTexts["Bitcoin"], "Cash segment should hide crypto")

        selectSegment("Crypto")
        assertExists(app.staticTexts["Bitcoin"], "Crypto segment should keep crypto")
        assertEventuallyGone(app.staticTexts["US Dollar"], "Crypto segment should hide fiat")
    }

    func testSearchFiltersCurrencies() {
        openCurrencyList()
        selectSegment("All")
        assertExists(app.staticTexts["US Dollar"])

        let search = revealSearchField()
        assertExists(search, "Search field should be available")
        search.tap()
        search.typeText("Sol")

        assertExists(app.staticTexts["Solana"], "Search 'Sol' should surface Solana")
        assertEventuallyGone(app.staticTexts["US Dollar"], "Search 'Sol' should hide non-matches")

        // Clearing the query must restore the full list. This second change is a
        // regression guard for the (fixed) stale-by-one filtering: a one-change
        // lag would leave the list showing the "Sol" results after clearing.
        let clearButton = search.buttons["Clear text"]
        if clearButton.waitForExistence(timeout: 2) {
            clearButton.tap()
        } else {
            search.tap()
            search.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 4))
        }
        assertExists(app.staticTexts["US Dollar"], "Clearing the search should restore the full list")
    }

    func testFavoriteToggleReflectsInFavoritesSegment() {
        openCurrencyList()
        selectSegment("All")

        let gbpRow = app.buttons[AXID.List.row("GBP")]
        assertExists(gbpRow, "GBP row should be present on the All segment")
        // GBP is not one of the seeded favorites (BTC/EUR/USD).
        waitForValue(gbpRow, equals: AXID.Value.unsaved, "GBP should start unsaved")

        // Favorite GBP (the 4th favorite — still under the free-tier limit of 5).
        gbpRow.tap()
        waitForValue(gbpRow, equals: AXID.Value.saved, "GBP should become saved after tap")

        // It now appears under the Favorite segment.
        selectSegment("Favorite")
        assertExists(app.staticTexts["British Pound"], "Favorited GBP should appear under Favorite")

        // Unfavorite from the All segment and confirm it leaves Favorite.
        selectSegment("All")
        let gbpAgain = app.buttons[AXID.List.row("GBP")]
        assertExists(gbpAgain)
        gbpAgain.tap()
        selectSegment("Favorite")
        assertEventuallyGone(app.staticTexts["British Pound"], "Unfavorited GBP should leave the Favorite segment")
    }

    func testFavoritingBeyondFreeLimitShowsPaywall() {
        openCurrencyList()
        selectSegment("All")

        // 3 favorites are seeded (BTC/EUR/USD). Favoriting ETH and GBP reaches
        // the free-tier limit of 5; a sixth favorite must present the paywall.
        for code in ["ETH", "GBP"] {
            let row = app.buttons[AXID.List.row(code)]
            assertExists(row, "\(code) row should be present")
            row.tap()
            waitForValue(row, equals: AXID.Value.saved, "\(code) should be favorited")
        }

        let sixth = app.buttons[AXID.List.row("JPY")]
        assertExists(sixth, "JPY row should be present")
        sixth.tap()

        assertExists(
            app.staticTexts[AXID.Subscription.title],
            "Favoriting beyond the free-tier limit should present the subscription paywall"
        )
    }

    func testBackNavigationReturnsToConverter() {
        openCurrencyList()
        // The back button is labeled with the previous title, "Rates".
        let backButton = app.navigationBars["Currencies List"].buttons.firstMatch
        assertExists(backButton)
        backButton.tap()
        assertExists(ratesNavBar, "Back navigation should return to the converter")
    }
}
