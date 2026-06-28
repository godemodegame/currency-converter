//
//  IntentHandler.swift
//  WidgetIntent
//
//  Created by Kirill Kirilenko on 03/05/2023.
//

import Intents
import CurrencyCore

final class IntentHandler: INExtension, ConfigurationIntentHandling {

    // MARK: Private properties

    @UserDefault(UserDefaultsKey.favoriteCurrencies, defaultValue: [])
    private var favoriteCurrencies: [String]

    private let currencyService: any CurrencyServiceProtocol = CurrencyService()

    // MARK: ConfigurationIntentHandling

    func provideCurrency1OptionsCollection(
        for intent: ConfigurationIntent,
        searchTerm: String?
    ) async throws -> INObjectCollection<CurrencyName> {
        try await provideOptions(searchTerm: searchTerm)
    }
    
    func provideCurrency2OptionsCollection(
        for intent: ConfigurationIntent,
        searchTerm: String?
    ) async throws -> INObjectCollection<CurrencyName> {
        try await provideOptions(searchTerm: searchTerm)
    }
    
    func provideCurrency3OptionsCollection(
        for intent: ConfigurationIntent,
        searchTerm: String?
    ) async throws -> INObjectCollection<CurrencyName> {
        try await provideOptions(searchTerm: searchTerm)
    }
    
    func provideBaseCurrencyOptionsCollection(
        for intent: ConfigurationIntent,
        searchTerm: String?
    ) async throws -> INObjectCollection<CurrencyName> {
        try await provideOptions(searchTerm: searchTerm)
    }

    // MARK: Private methods

    private func provideOptions(
        searchTerm: String?
    ) async throws -> INObjectCollection<CurrencyName> {
        if let searchTerm {
            return try await search(searchTerm)
        } else {
            return try await fetchCurrencies()
        }
    }

    private func search(_ searchTerm: String) async throws -> INObjectCollection<CurrencyName> {
        let normalizedSearchTerm = searchTerm.lowercased()
        return INObjectCollection(
            sections: [
                INObjectSection(
                    title: "",
                    items: try await currencyService.getSavedCurrenciesOrFetch()
                        .filter {
                            $0.name.lowercased().contains(normalizedSearchTerm)
                            || $0.code.lowercased().contains(normalizedSearchTerm)
                        }
                        .map { currency in
                            CurrencyName(
                                identifier: currency.code,
                                display: currency.name,
                                subtitle: currency.code,
                                image: nil
                            )
                        }
                )
            ]
        )
    }

    private func fetchCurrencies() async throws -> INObjectCollection<CurrencyName> {
        let currencies = try await currencyService.getSavedCurrenciesOrFetch()
        return INObjectCollection(
            sections: [
                INObjectSection(
                    title: "Favorites",
                    items: currencies
                        .filter { favoriteCurrencies.contains($0.code) }
                        .map { currency in
                            CurrencyName(
                                identifier: currency.code,
                                display: currency.name,
                                subtitle: currency.code,
                                image: nil
                            )
                        }
                ),
                INObjectSection(
                    title: "Cash",
                    items: currencies
                        .filter { $0.type == .fiat && !favoriteCurrencies.contains($0.code) }
                        .map { currency in
                            CurrencyName(
                                identifier: currency.code,
                                display: currency.name,
                                subtitle: currency.code,
                                image: nil
                            )
                        }
                ),
                INObjectSection(
                    title: "Crypto",
                    items: currencies
                        .filter { $0.type == .crypto && !favoriteCurrencies.contains($0.code) }
                        .map { currency in
                            CurrencyName(
                                identifier: currency.code,
                                display: currency.name,
                                subtitle: currency.code,
                                image: nil
                            )
                        }
                )
            ]
        )
    }
}
