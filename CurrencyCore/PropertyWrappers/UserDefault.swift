//
//  UserDefaults.swift
//  CurrencyConverter
//
//  Created by Kirill Kirilenko on 29/04/2023.
//

@propertyWrapper
public struct UserDefault<T> {
    public let key: String
    public let defaultValue: T
    public let userDefaults: UserDefaults

    public init(
        _ key: String,
        defaultValue: T,
        userDefaults: UserDefaults = UserDefaults(suiteName: "group.gmg.CurrencyConverter") ?? .standard
    ) {
        self.key = key
        self.defaultValue = defaultValue
        self.userDefaults = userDefaults
    }

    public var wrappedValue: T {
        get {
            if T.self == [Currency].self, let data = userDefaults.data(forKey: key) {
                let decoded = try? JSONDecoder().decode([Currency].self, from: data)
                return (decoded as? T) ?? defaultValue
            } else {
                return userDefaults.object(forKey: key) as? T ?? defaultValue
            }
        } set {
            if let value = newValue as? [Currency], let encoded = try? JSONEncoder().encode(value) {
                userDefaults.set(encoded, forKey: key)
            } else {
                userDefaults.set(newValue, forKey: key)
            }
        }
    }
}
