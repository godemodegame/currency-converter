//
//  CryptoWorker.swift
//  CurrencyCore
//
//  Created by Kirill Kirilenko on 03/05/2023.
//

import Foundation

public protocol CryptoCurrencyWorker: AnyObject {
    func prepareCurrencies(_ markets: [CoinGeckoMarket]) throws -> [Currency]
}

public final class CryptoWorker: CryptoCurrencyWorker {
    public init() {}

    /// Maps CoinGecko market rows straight to `Currency`. The endpoint already
    /// supplies name/symbol/icon, so there's no plist enrichment: a row is kept
    /// only when it has a usable USD price and icon URL. The code is the
    /// upper-cased ticker; same-symbol collisions are resolved upstream in
    /// `CurrencyService` (market-cap order means the largest coin wins).
    public func prepareCurrencies(_ markets: [CoinGeckoMarket]) throws -> [Currency] {
        markets.compactMap { market in
            guard let price = market.currentPrice, price > 0,
                  let image = URL(string: market.image) else { return nil }
            return Currency(
                name: market.name,
                imageSource: .image(image),
                code: market.symbol.uppercased(),
                rate: 1 / price,
                type: .crypto
            )
        }
    }
}
