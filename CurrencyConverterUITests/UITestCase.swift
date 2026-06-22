//
//  UITestCase.swift
//  CurrencyConverterUITests
//
//  Base class for the app's XCUITest suites. Launches the app in the
//  deterministic UI-test mode backed by `UITestConfig` / `UITestStubCurrencyService`
//  in the app target (stubbed currency data, seeded favorites, no ads, onboarding
//  skipped unless requested).
//

import XCTest

class UITestCase: XCTestCase {
    var app: XCUIApplication!

    /// Generous timeout for the first element after launch (Firebase / ads SDK
    /// init plus the initial SwiftUI render); shorter for follow-up assertions.
    let launchTimeout: TimeInterval = 15
    let defaultTimeout: TimeInterval = 6

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() {
        app?.terminate()
        app = nil
        super.tearDown()
    }

    /// Launches the app in UI-test mode.
    /// - Parameter onboarding: when `true`, the first-launch onboarding flow is
    ///   shown (running with its animations collapsed to instant); otherwise it
    ///   is skipped and the app opens straight to the converter.
    @discardableResult
    func launchApp(onboarding: Bool = false) -> XCUIApplication {
        app.launchArguments = [UITestLaunchArgument.activation]
        if onboarding {
            app.launchArguments.append(UITestLaunchArgument.onboarding)
        }
        app.launch()
        return app
    }

    // MARK: - Helpers

    /// The main converter screen's navigation bar ("Rates").
    var ratesNavBar: XCUIElement { app.navigationBars["Rates"] }

    @discardableResult
    func assertExists(
        _ element: XCUIElement,
        timeout: TimeInterval? = nil,
        _ message: String = "",
        file: StaticString = #file,
        line: UInt = #line
    ) -> Bool {
        let exists = element.waitForExistence(timeout: timeout ?? defaultTimeout)
        XCTAssertTrue(exists, message.isEmpty ? "Expected element to exist: \(element)" : message, file: file, line: line)
        return exists
    }

    func assertEventuallyGone(
        _ element: XCUIElement,
        timeout: TimeInterval? = nil,
        _ message: String = "",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let gone = element.waitForNonExistence(timeout: timeout ?? defaultTimeout)
        XCTAssertTrue(gone, message.isEmpty ? "Expected element to disappear: \(element)" : message, file: file, line: line)
    }

    /// Polls until `element.isHittable` (lists/sheets may need a beat to settle).
    @discardableResult
    func waitForHittable(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "isHittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    /// Waits for an element's `value` to equal `expected` (accessibility values
    /// update asynchronously after a tap re-renders SwiftUI, so a single-shot
    /// `element.value` read can race the re-render).
    func waitForValue(
        _ element: XCUIElement,
        equals expected: String,
        _ message: String = "",
        timeout: TimeInterval? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let predicate = NSPredicate(format: "value == %@", expected)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout ?? defaultTimeout)
        let detail = "Expected value '\(expected)' but was '\(String(describing: element.value))'"
        XCTAssertEqual(
            result, .completed,
            message.isEmpty ? detail : "\(message) — \(detail)",
            file: file, line: line
        )
    }

    /// Taps an element once it exists and is hittable, nudging the scroll view
    /// only if needed and re-confirming hittability before the tap.
    func tapWhenReady(
        _ element: XCUIElement,
        timeout: TimeInterval? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard assertExists(element, timeout: timeout, file: file, line: line) else { return }
        if !waitForHittable(element, timeout: 2) {
            app.swipeUp()
            _ = waitForHittable(element, timeout: timeout ?? defaultTimeout)
        }
        element.tap()
    }
}
