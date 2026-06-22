//
//  TestSupport.swift
//  CurrencyConverterTests
//
//  Builders and app-group favorites helpers shared by the app-hosted tests.
//

import Foundation
import CurrencyCore

func makeCurrency(
    _ code: String,
    rate: Double = 1,
    type: CurrencyType = .fiat,
    name: String? = nil,
    imageSource: ImageSource = .flag("🏳️")
) -> Currency {
    Currency(name: name ?? code, imageSource: imageSource, code: code, rate: rate, type: type)
}

func decodeJSON<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
    try JSONDecoder().decode(T.self, from: Data(json.utf8))
}

func isApprox(_ a: Double, _ b: Double, tolerance: Double = 1e-9) -> Bool {
    abs(a - b) <= tolerance
}

enum FavoritesStore {
    /// Replaces the persisted favorites with `codes` (or clears them when nil).
    /// ViewModels read `favoriteCurrencies` from the shared app-group suite, so
    /// seed it *before* constructing the ViewModel.
    static func seed(_ codes: [String]?) {
        if let codes {
            AppGroup.userDefaults.set(codes, forKey: UserDefaultsKey.favoriteCurrencies)
        } else {
            AppGroup.userDefaults.removeObject(forKey: UserDefaultsKey.favoriteCurrencies)
        }
    }

    static var current: [String] {
        AppGroup.userDefaults.array(forKey: UserDefaultsKey.favoriteCurrencies) as? [String] ?? []
    }
}

/// A representative mixed list (3 fiat + 1 crypto) for filter/conversion tests.
func sampleCurrencies() -> [Currency] {
    [
        makeCurrency("USD", rate: 1, type: .fiat, name: "US Dollar"),
        makeCurrency("EUR", rate: 0.92, type: .fiat, name: "Euro"),
        makeCurrency("GBP", rate: 0.79, type: .fiat, name: "British Pound"),
        makeCurrency("BTC", rate: 0.00002, type: .crypto, name: "Bitcoin")
    ]
}
