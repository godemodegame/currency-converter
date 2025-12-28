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
    private let plistFileUrl: URL?

    // Mapping from CoinGecko IDs to app codes
    private let reverseMapping: [String: String] = [
        "bitcoin": "BTC",
        "ethereum": "ETH",
        "tether": "USDT",
        "usd-coin": "USDC",
        "uniswap": "UNI",
        "true-usd": "TUSD",
        "tron": "TRX",
        "the-open-network": "TON",
        "solana": "SOL",
        "polygon-ecosystem-token": "MATIC",
        "dai": "DAI",
        "aave": "AAVE",
        "ripple": "XRP",
        "binancecoin": "BNB",
        "cardano": "ADA",
        "dogecoin": "DOGE",
        "avalanche-2": "AVAX",
        "polkadot": "DOT",
        "chainlink": "LINK",
        "shiba-inu": "SHIB",
        "litecoin": "LTC",
        "bitcoin-cash": "BCH",
        "cosmos": "ATOM",
        "pepe": "PEPE",
        "pancakeswap-token": "CAKE",
        "curve-dao-token": "CRV",
        "sushi": "SUSHI",
        "compound-governance-token": "COMP",
        "maker": "MKR"
    ]

    public init() {
        plistFileUrl = Bundle.main.url(
            forResource: "CryptoInfo",
            withExtension: "plist"
        )
    }

    public func prepareCurrencies(_ dict: [String: CoinGeckoResponse]) throws -> [Currency] {
        guard let plistFileUrl else {
            throw CurrencyError.missingPlistFile
        }
        let data = try Data(contentsOf: plistFileUrl)
        let currencyPlist = try PropertyListDecoder()
            .decode(Plist<CryptoInfo>.self, from: data)

        return dict.compactMap { (coinGeckoId, response) in
            guard let code = reverseMapping[coinGeckoId] else { return nil }
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
