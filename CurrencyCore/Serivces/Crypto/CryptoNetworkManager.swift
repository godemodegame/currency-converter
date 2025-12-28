//
//  CryptoNetworkManager.swift
//  CurrencyCore
//
//  Created by Kirill Kirilenko on 03/05/2023.
//

public protocol CryptoNetworkManager: AnyObject {
    func getExchangeRates() async throws -> [String: CoinGeckoResponse]
}

public final class CoinGeckoNetworkManager: CryptoNetworkManager {
    private let baseUrl: String

    // Mapping from app codes to CoinGecko IDs
    private let coinMapping: [String: String] = [
        "BTC": "bitcoin",
        "ETH": "ethereum",
        "USDT": "tether",
        "USDC": "usd-coin",
        "UNI": "uniswap",
        "TUSD": "true-usd",
        "TRX": "tron",
        "TON": "the-open-network",
        "SOL": "solana",
        "MATIC": "polygon-ecosystem-token",
        "DAI": "dai",
        "AAVE": "aave",
        "XRP": "ripple",
        "BNB": "binancecoin",
        "ADA": "cardano",
        "DOGE": "dogecoin",
        "AVAX": "avalanche-2",
        "DOT": "polkadot",
        "LINK": "chainlink",
        "SHIB": "shiba-inu",
        "LTC": "litecoin",
        "BCH": "bitcoin-cash",
        "ATOM": "cosmos",
        "PEPE": "pepe",
        "CAKE": "pancakeswap-token",
        "CRV": "curve-dao-token",
        "SUSHI": "sushi",
        "COMP": "compound-governance-token",
        "MKR": "maker"
    ]

    public init(baseUrl: String = "https://api.coingecko.com") {
        self.baseUrl = baseUrl
    }

    public func getExchangeRates() async throws -> [String: CoinGeckoResponse] {
        let ids = coinMapping.values.joined(separator: ",")
        guard let url = URL(string: "\(baseUrl)/api/v3/simple/price?ids=\(ids)&vs_currencies=usd") else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode([String: CoinGeckoResponse].self, from: data)

        return response
    }
}

// Legacy type alias for compatibility
public typealias DedustNetworkManager = CoinGeckoNetworkManager
