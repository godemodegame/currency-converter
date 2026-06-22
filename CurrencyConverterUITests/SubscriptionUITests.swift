//
//  SubscriptionUITests.swift
//  CurrencyConverterUITests
//
//  Covers presenting the subscription paywall from the "Remove ads" toolbar
//  entry point and dismissing it.
//

import XCTest

final class SubscriptionUITests: UITestCase {
    func testRemoveAdsOpensPaywall() {
        launchApp()
        assertExists(ratesNavBar, timeout: launchTimeout)

        tapWhenReady(app.buttons[AXID.Nav.removeAdsButton])

        assertExists(app.staticTexts[AXID.Subscription.title], "Paywall title should appear")
        assertExists(app.buttons[AXID.Subscription.subscribeButton], "Subscribe button should appear")
        assertExists(app.buttons[AXID.Subscription.cancelButton], "Cancel button should appear")
    }

    func testPaywallDismissesOnCancel() {
        launchApp()
        assertExists(ratesNavBar, timeout: launchTimeout)

        tapWhenReady(app.buttons[AXID.Nav.removeAdsButton])
        assertExists(app.buttons[AXID.Subscription.cancelButton])

        app.buttons[AXID.Subscription.cancelButton].tap()

        assertEventuallyGone(app.staticTexts[AXID.Subscription.title], "Paywall should dismiss on Cancel")
        assertExists(ratesNavBar, "Dismissing the paywall should reveal the converter again")
    }
}
