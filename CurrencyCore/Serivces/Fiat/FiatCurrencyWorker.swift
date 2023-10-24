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
    private let plistFileUrl: URL?

    public init() {
        plistFileUrl = Bundle.main.url(
            forResource: "CurrenciesInfo",
            withExtension: "plist"
        )
    }

    public func prepareCurrencies(_ dict: ExchangeRatesResponse) throws -> [Currency] {
        guard let plistFileUrl else {
            throw CurrencyError.missingPlistFile
        }
        let data = try Data(contentsOf: plistFileUrl)
        let currencyPlist = try PropertyListDecoder()
            .decode(Plist<CurrencyInfo>.self, from: data)
        return dict.rates.map { rate in
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
