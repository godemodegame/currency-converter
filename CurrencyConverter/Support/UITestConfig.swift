//
//  UITestConfig.swift
//  CurrencyConverter
//
//  Opt-in support for deterministic UI testing. Everything here is a no-op
//  unless the app is launched with the `UITESTS` launch argument, so normal
//  app behavior is completely unchanged in production.
//
//  When active it:
//    • forces the first-launch onboarding on/off deterministically,
//    • seeds a fixed set of favorite currencies into the shared app group,
//    • clears any persisted currency snapshot, and
//    • makes onboarding animations resolve instantly + skips the ATT prompt.
//
//  The app pairs this with `UITestStubCurrencyService` so the screens are
//  populated from fixtures instead of the live network.
//
//  The launch arguments are intentionally NOT prefixed with "-": a leading
//  dash would make `UserDefaults` parse them into its argument domain. Plain
//  tokens stay out of `UserDefaults` and are matched via `arguments.contains`.
//

import CurrencyCore
import Foundation

enum UITestConfig {
    static var isActive: Bool {
        ProcessInfo.processInfo.arguments.contains(UITestLaunchArgument.activation)
    }

    /// Whether the onboarding flow should be presented this launch.
    static var showsOnboarding: Bool {
        isActive && ProcessInfo.processInfo.arguments.contains(UITestLaunchArgument.onboarding)
    }

    /// Hide the ad banner under tests so the GoogleMobileAds SDK doesn't add
    /// network/layout noise (the "Remove ads" entry point stays visible).
    static var hideAds: Bool { isActive }

    /// Collapse onboarding's timed reveal animations to instant so the flow is
    /// deterministic instead of racing `Task.sleep`.
    static var instantAnimations: Bool { isActive }

    /// Favorites seeded into the shared app group when test mode skips
    /// onboarding. The stub service returns currencies that include these.
    static let seededFavoriteCodes = ["BTC", "EUR", "USD"]

    /// Applies the deterministic launch state. Safe to call unconditionally;
    /// returns immediately when not in test mode.
    static func bootstrapIfNeeded() {
        guard isActive else { return }

        // Drive (or skip) the first-launch onboarding deterministically. The
        // "isFirstOpen" key is the app's `@AppStorage` flag, in `.standard`.
        UserDefaults.standard.set(showsOnboarding, forKey: "isFirstOpen")

        if showsOnboarding {
            // Let ContentView's own first-launch path seed favorites.
            return
        }

        // Seed a known favorites set so the converter / favorites segment are
        // populated without walking onboarding.
        AppGroup.userDefaults.set(
            seededFavoriteCodes,
            forKey: UserDefaultsKey.favoriteCurrencies
        )
        // Drop any persisted snapshot so the stub service is the only source.
        AppGroup.userDefaults.removeObject(forKey: UserDefaultsKey.savedCurrencies)
    }
}
