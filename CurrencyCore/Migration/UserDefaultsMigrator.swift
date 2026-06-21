//
//  UserDefaultsMigrator.swift
//  CurrencyCore
//
//  One-time migration of pre-app-group UserDefaults into the shared suite.
//

import Foundation

public struct UserDefaultsMigrator {
    private let legacy: UserDefaults
    private let shared: UserDefaults

    public init(
        legacy: UserDefaults = .standard,
        shared: UserDefaults = AppGroup.userDefaults
    ) {
        self.legacy = legacy
        self.shared = shared
    }

    /// Copies pre-app-group data into the shared suite.
    /// Idempotent: a key is copied only when the legacy store has a value AND the
    /// shared store does not, so it never clobbers newer shared data and is safe to
    /// call on every launch. The legacy key is cleared after a successful copy.
    public func migrateIfNeeded() {
        migrateSavedCurrencies()
        migrateFavoriteCurrencies()
    }

    /// `savedCurrencies` is stored as JSON `Data` (see `CodableUserDefault`); copy the
    /// bytes verbatim so the decoder reads them identically.
    private func migrateSavedCurrencies() {
        let key = UserDefaultsKey.savedCurrencies
        guard let legacyData = legacy.data(forKey: key),
              shared.data(forKey: key) == nil else { return }
        shared.set(legacyData, forKey: key)
        legacy.removeObject(forKey: key)
    }

    /// `favoriteCurrencies` is stored as a native `[String]` array (see `UserDefault`).
    private func migrateFavoriteCurrencies() {
        let key = UserDefaultsKey.favoriteCurrencies
        guard let legacyFavorites = legacy.array(forKey: key) as? [String],
              !legacyFavorites.isEmpty,
              (shared.array(forKey: key) as? [String]) == nil else { return }
        shared.set(legacyFavorites, forKey: key)
        legacy.removeObject(forKey: key)
    }
}
