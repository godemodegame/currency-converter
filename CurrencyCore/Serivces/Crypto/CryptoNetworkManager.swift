//
//  CryptoNetworkManager.swift
//  CurrencyCore
//
//  Created by Kirill Kirilenko on 03/05/2023.
//

import Foundation

public protocol CryptoNetworkManager: AnyObject {
    func getExchangeRates() async throws -> [String: CoinGeckoResponse]
}

public final class CoinGeckoNetworkManager: CryptoNetworkManager {
    private let baseUrl: String
    private let client: NetworkClient

    public init(
        baseUrl: String = "https://api.coingecko.com",
        client: NetworkClient = URLSessionNetworkClient()
    ) {
        self.baseUrl = baseUrl
        self.client = client
    }

    public func getExchangeRates() async throws -> [String: CoinGeckoResponse] {
        let ids = CoinMapping.appCodeToCoinGeckoId.values.joined(separator: ",")
        return try await client.get(
            baseURL: baseUrl,
            path: "/api/v3/simple/price",
            queryItems: [
                URLQueryItem(name: "ids", value: ids),
                URLQueryItem(name: "vs_currencies", value: "usd")
            ],
            as: [String: CoinGeckoResponse].self
        )
    }
}
