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

    @UserDefault("favoriteCurrencies", defaultValue: [])
    private var favoriteCurrencies: [String]

    private let currencyService: any CurrencyServiceProtocol = CurrencyService()

    // MARK: ConfigurationIntentHandling

    func provideCurrency1OptionsCollection(
        for intent: ConfigurationIntent,
        searchTerm: String?
    ) async throws -> INObjectCollection<CurrencyName> {
        if let searchTerm {
            return await search(searchTerm)
        } else {
            return await fetchCurrencies()
        }
    }
    
    func provideCurrency2OptionsCollection(
        for intent: ConfigurationIntent,
        searchTerm: String?
    ) async throws -> INObjectCollection<CurrencyName> {
        if let searchTerm {
            return await search(searchTerm)
        } else {
            return await fetchCurrencies()
        }
    }
    
    func provideCurrency3OptionsCollection(
        for intent: ConfigurationIntent,
        searchTerm: String?
    ) async throws -> INObjectCollection<CurrencyName> {
        if let searchTerm {
            return await search(searchTerm)
        } else {
            return await fetchCurrencies()
        }
    }
    
    func provideBaseCurrencyOptionsCollection(
        for intent: ConfigurationIntent,
        searchTerm: String?
    ) async throws -> INObjectCollection<CurrencyName> {
        if let searchTerm {
            return await search(searchTerm)
        } else {
            return await fetchCurrencies()
        }
    }

    // MARK: Private methods

    private func search(_ searchTerm: String) async -> INObjectCollection<CurrencyName> {
        INObjectCollection(
            sections: [
                INObjectSection(
                    title: "",
                    items: await currencyService.getSavedCurrencies()
                        .filter {
                            $0.name.lowercased().contains(searchTerm.lowercased())
                            || $0.code.lowercased().contains(searchTerm.lowercased())
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

    private func fetchCurrencies() async -> INObjectCollection<CurrencyName> {
        let currencies = await currencyService.getSavedCurrencies()
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
                    title: "Fiat",
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
                ),
                INObjectSection(
                    title: "Jettons",
                    items: currencies
                        .filter { $0.type == .jetton && !favoriteCurrencies.contains($0.code) }
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
