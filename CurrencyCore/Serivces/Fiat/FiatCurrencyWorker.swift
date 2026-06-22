//
//  CurrencyWorker.swift
//  CurrencyCore
//
//  Created by Kirill Kirilenko on 29/04/2023.
//

import SwiftFlags

public protocol FiatCurrencyWorker: AnyObject {
    func prepareCurrencies(_ dict: ExchangeRatesResponse) throws -> [Currency]
}

public final class FiatWorker: FiatCurrencyWorker {
    public init() {}

    public func prepareCurrencies(_ dict: ExchangeRatesResponse) throws -> [Currency] {
        let currencyPlist = try Plist<CurrencyInfo>.load(resource: "CurrenciesInfo")
        // Frankfurter omits the base currency from `rates` (it's implied as
        // `amount`, e.g. USD = 1.0), so fold it back in — otherwise the
        // canonical base never appears in the list.
        var rates = dict.rates
        rates[dict.base] = dict.amount
        return rates.map { rate in
            let info = currencyPlist.currencies.first { $0.code == rate.key }
            return Currency(
                name: info?.name ?? "",
                imageSource: .flag(SwiftFlags.flag(for: info?.country ?? "") ?? ""),
                code: rate.key,
                rate: rate.value,
                type: .fiat
            )
        }.filter {
            if case .flag(let flag) = $0.imageSource {
                return !$0.name.isEmpty && !flag.isEmpty
            } else {
                return false
            }
        }
    }
}
