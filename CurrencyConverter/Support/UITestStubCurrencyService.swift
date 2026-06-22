//
//  UITestStubCurrencyService.swift
//  CurrencyConverter
//
//  A deterministic, network-free `CurrencyServiceProtocol` used only when the
//  app is launched in UI-test mode (`UITestConfig.isActive`). It returns a
//  fixed fixture list so the converter and the currencies list are fully
//  reproducible without hitting Frankfurter / CoinGecko.
//

import CurrencyCore
import Foundation

final class UITestStubCurrencyService: CurrencyServiceProtocol {
    func getCurrencies() async throws -> [Currency] {
        UITestFixtures.currencies
    }

    func getSavedCurrencies() async -> [Currency] {
        UITestFixtures.currencies
    }
}

enum UITestFixtures {
    /// All rates are expressed against the canonical USD base, matching the
    /// real service's contract. Values are illustrative — tests assert on
    /// names/codes/structure, never on exact formatted rates.
    static let currencies: [Currency] = [
        Currency(name: "Bitcoin", imageSource: .image(iconURL("btc")), code: "BTC", rate: 0.0000159, type: .crypto),
        Currency(name: "Ethereum", imageSource: .image(iconURL("eth")), code: "ETH", rate: 0.00032, type: .crypto),
        Currency(name: "Euro", imageSource: .flag("🇪🇺"), code: "EUR", rate: 0.92, type: .fiat),
        Currency(name: "British Pound", imageSource: .flag("🇬🇧"), code: "GBP", rate: 0.79, type: .fiat),
        Currency(name: "Japanese Yen", imageSource: .flag("🇯🇵"), code: "JPY", rate: 150.0, type: .fiat),
        Currency(name: "Solana", imageSource: .image(iconURL("sol")), code: "SOL", rate: 0.0065, type: .crypto),
        Currency(name: "US Dollar", imageSource: .flag("🇺🇸"), code: "USD", rate: 1.0, type: .fiat),
    ]

    private static func iconURL(_ slug: String) -> URL {
        URL(string: "https://example.com/crypto/\(slug).png")!
    }
}
