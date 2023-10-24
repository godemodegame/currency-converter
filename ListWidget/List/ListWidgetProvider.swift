//
//  ListWidgetProvider.swift
//  CurrencyConverter
//
//  Created by Kirill Kirilenko on 03/05/2023.
//

import CurrencyCore
import Intents
import WidgetKit

struct ListWidgetProvider: IntentTimelineProvider {
    // MARK: Private properties
    private let currencyService: any CurrencyServiceProtocol = CurrencyService()

    // MARK: IntentTimelineProvider

    func placeholder(in _: Context) -> WidgetEntry {
        WidgetEntry(
            date: Date(),
            currencies: [],
            error: nil,
            configuration: ConfigurationIntent()
        )
    }

    func getSnapshot(
        for configuration: ConfigurationIntent,
        in _: Context,
        completion: @escaping (WidgetEntry) -> ()
    ) {
        Task {
            do {
                completion(
                    WidgetEntry(
                        date: Date(),
                        currencies: try await createCurrencyModels(
                            configuration: configuration
                        ),
                        error: nil,
                        configuration: configuration
                    )
                )
            } catch {
                completion(
                    WidgetEntry(
                        date: Date(),
                        currencies: [],
                        error: error,
                        configuration: configuration
                    )
                )
            }
        }
    }

    func getTimeline(
        for configuration: ConfigurationIntent,
        in _: Context,
        completion: @escaping (Timeline<WidgetEntry>) -> ()
    ) {
        Task {
            do {
                completion(
                    Timeline(
                        entries: [
                            WidgetEntry(
                                date: .now,
                                currencies: try await createCurrencyModels(
                                    configuration: configuration
                                ),
                                error: nil,
                                configuration: configuration
                            )
                        ],
                        policy: .atEnd
                    )
                )
            } catch {
                completion(
                    Timeline(
                        entries: [
                            WidgetEntry(
                                date: Date(),
                                currencies: [],
                                error: error,
                                configuration: configuration
                            )
                        ],
                        policy: .atEnd
                    )
                )
            }
        }
    }

    // MARK: Private properties

    private func createCurrencyModels(
        configuration: ConfigurationIntent
    ) async throws -> [CurrencyModel] {
        let currencies = try await currencyService.getCurrencies()
        guard let baseCurrency = currencies.first(where: { $0.code == (configuration.BaseCurrency?.identifier ?? "USD") }) else {
            return []
        }
        return [
            configuration.Currency1?.identifier ?? "EUR",
            configuration.Currency2?.identifier ?? "GBP",
            configuration.Currency3?.identifier ?? "BTC"
        ].compactMap { rate in
            guard let currency = currencies.first(where: {
                $0.code == rate
            }) else {
                return nil
            }
            return CurrencyModel(
                name: currency.code,
                image: nil,
                baseName: baseCurrency.code,
                rate: currency.rate / baseCurrency.rate
            )
        }
    }
}
