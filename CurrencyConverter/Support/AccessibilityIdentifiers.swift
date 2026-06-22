//
//  AccessibilityIdentifiers.swift
//  CurrencyConverter
//
//  Stable accessibility identifiers shared between the app and the UI test
//  target. This file is compiled into BOTH targets (see the pbxproj), so the
//  app and the tests reference the exact same string constants — element
//  queries never drift from the views they target.
//
//  Keep this file dependency-free (Foundation only) so it can live in the UI
//  test bundle, which cannot import the app module.
//

import Foundation

/// Launch-argument tokens shared by the app (`UITestConfig`) and the UI test
/// target's launch helper. Deliberately undashed so `UserDefaults` never
/// adopts them into its argument domain.
enum UITestLaunchArgument {
    static let activation = "UITESTS"
    static let onboarding = "UITESTS_ONBOARDING"
}

enum AXID {
    enum Nav {
        static let addButton = "nav.addButton"
        static let removeAdsButton = "nav.removeAdsButton"
    }

    enum Converter {
        static let list = "converter.list"
        static let emptyPrompt = "converter.emptyPrompt"
        static let amountField = "converter.amountField"
        static let currencyPicker = "converter.currencyPicker"
    }

    enum List {
        static let segmentedControl = "list.segmentedControl"

        static func row(_ code: String) -> String { "list.row.\(code)" }
    }

    enum Subscription {
        static let title = "subscription.title"
        static let subscribeButton = "subscription.subscribeButton"
        static let cancelButton = "subscription.cancelButton"
    }

    enum Onboarding {
        static let firstContinue = "onboarding.first.continue"
        static let secondContinue = "onboarding.second.continue"
        static let thirdContinue = "onboarding.third.continue"
        static let support = "onboarding.last.support"
        static let maybeLater = "onboarding.last.maybeLater"
    }

    /// Accessibility *values* (read via `element.value` in tests), used where a
    /// single element carries mutable state — e.g. a list row's saved/unsaved
    /// bookmark, which SwiftUI folds into the row button's accessibility element.
    enum Value {
        static let saved = "saved"
        static let unsaved = "unsaved"
    }
}
