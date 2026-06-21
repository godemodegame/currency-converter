//
//  CryptoWorker.swift
//  CurrencyCore
//
//  Created by Kirill Kirilenko on 03/05/2023.
//

public protocol CryptoCurrencyWorker: AnyObject {
    func prepareCurrencies(_ dict: [String: CoinGeckoResponse]) throws -> [Currency]
}

public final class CryptoWorker: CryptoCurrencyWorker {
    public init() {}

    public func prepareCurrencies(_ dict: [String: CoinGeckoResponse]) throws -> [Currency] {
        let currencyPlist = try Plist<CryptoInfo>.load(resource: "CryptoInfo")

        return dict.compactMap { (coinGeckoId, response) in
            guard let code = CoinMapping.coinGeckoIdToAppCode[coinGeckoId] else { return nil }
            let info = currencyPlist.currencies.first { $0.code == code }

            if let info, let image = URL(string: info.imageUrl) {
                return Currency(
                    name: info.name,
                    imageSource: .image(image),
                    code: code,
                    rate: 1 / response.usd,
                    type: .crypto
                )
            } else {
                return nil
            }
        }
    }
}
