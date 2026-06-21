//
//  UserDefaults.swift
//  CurrencyConverter
//
//  Created by Kirill Kirilenko on 29/04/2023.
//

import Foundation

@propertyWrapper
public struct UserDefault<T> {
    public let key: String
    public let defaultValue: T
    public let userDefaults: UserDefaults

    public init(
        _ key: String,
        defaultValue: T,
        userDefaults: UserDefaults = AppGroup.userDefaults
    ) {
        self.key = key
        self.defaultValue = defaultValue
        self.userDefaults = userDefaults
    }

    /// Stores values UserDefaults supports natively (primitives, `[String]`, `Data`, …).
    /// For `Codable` types persisted as JSON `Data`, use `@CodableUserDefault` instead.
    public var wrappedValue: T {
        get { userDefaults.object(forKey: key) as? T ?? defaultValue }
        set { userDefaults.set(newValue, forKey: key) }
    }
}

/// Shared App Group used by the app and its widget / intent extensions.
public enum AppGroup {
    public static let suiteName = "group.gmg.CurrencyConverter"

    /// The shared suite, falling back to `.standard` when the group is unavailable.
    public static var userDefaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }
}

/// Canonical UserDefaults keys shared across the app, extensions, and migration.
public enum UserDefaultsKey {
    public static let favoriteCurrencies = "favoriteCurrencies"
    public static let savedCurrencies = "savedCurrencies"
}

/// App-wide currency defaults.
public enum CurrencyDefaults {
    /// Codes seeded into favorites on first launch.
    public static let favoriteCodes = ["USD", "EUR", "BTC"]
}
