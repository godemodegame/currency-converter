//
//  ConverterUITests.swift
//  CurrencyConverterUITests
//
//  Exercises the amount field (numeric entry, zero-clearing, decimals) and the
//  base-currency picker on the main converter screen.
//

import XCTest

final class ConverterUITests: UITestCase {
    private var amountField: XCUIElement { app.textFields[AXID.Converter.amountField] }

    private func launchToConverter() {
        launchApp()
        assertExists(ratesNavBar, timeout: launchTimeout)
        assertExists(amountField)
    }

    func testEnterDigitsUpdatesAmount() {
        launchToConverter()
        amountField.tap()
        amountField.typeText("150")
        waitForValue(amountField, equals: "150", "Digits should be accepted verbatim")
    }

    func testDecimalAmountAccepted() {
        launchToConverter()
        amountField.tap()
        amountField.typeText("12.5")
        waitForValue(amountField, equals: "12.5", "A decimal amount should be accepted")
    }

    func testZeroClearsAmount() {
        launchToConverter()
        amountField.tap()
        amountField.typeText("0")
        // Typing a value that parses to zero clears the field, so the value
        // falls back to the placeholder.
        waitForValue(amountField, equals: "Enter amount", "Entering 0 should clear the field")
    }

    func testCurrencyPickerSelectsBase() {
        launchToConverter()
        let picker = app.buttons[AXID.Converter.currencyPicker]
        assertExists(picker, "Currency picker should be present")
        picker.tap()

        // The favorites BTC / EUR / USD are the available options. The menu's
        // option may surface as a button or a menu item depending on the OS, so
        // wait for whichever presents rather than reading `.exists` synchronously.
        let eurOption = firstResolved(
            app.menuItems["EUR"],
            app.buttons["EUR"],
            timeout: defaultTimeout
        )
        XCTAssertNotNil(eurOption, "EUR should be a selectable base option")
        eurOption?.tap()

        // The picker now reflects the chosen base.
        let reflectsEUR = NSPredicate(format: "label CONTAINS 'EUR' OR value CONTAINS 'EUR'")
        expectation(for: reflectsEUR, evaluatedWith: picker)
        waitForExpectations(timeout: defaultTimeout)
    }

    /// Returns whichever candidate element exists first within `timeout`,
    /// polling so we don't race a presentation animation.
    private func firstResolved(_ candidates: XCUIElement..., timeout: TimeInterval) -> XCUIElement? {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let hit = candidates.first(where: { $0.exists }) { return hit }
            _ = candidates.first?.waitForExistence(timeout: 0.3)
        }
        return candidates.first(where: { $0.exists })
    }
}
