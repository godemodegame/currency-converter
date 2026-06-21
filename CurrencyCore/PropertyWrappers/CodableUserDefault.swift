//
//  CodableUserDefault.swift
//  CurrencyCore
//
//  Persists any Codable value as JSON Data in UserDefaults.
//

import Foundation

@propertyWrapper
public struct CodableUserDefault<T: Codable> {
    public let key: String
    public let defaultValue: T
    public let userDefaults: UserDefaults

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(
        _ key: String,
        defaultValue: T,
        userDefaults: UserDefaults = AppGroup.userDefaults
    ) {
        self.key = key
        self.defaultValue = defaultValue
        self.userDefaults = userDefaults
    }

    public var wrappedValue: T {
        get {
            guard let data = userDefaults.data(forKey: key),
                  let decoded = try? decoder.decode(T.self, from: data) else {
                return defaultValue
            }
            return decoded
        }
        set {
            guard let data = try? encoder.encode(newValue) else { return }
            userDefaults.set(data, forKey: key)
        }
    }
}
