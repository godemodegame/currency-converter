//
//  CryptoNetworkManager.swift
//  CurrencyCore
//
//  Created by Kirill Kirilenko on 03/05/2023.
//

import Foundation

public protocol CryptoNetworkManager: AnyObject {
    func getExchangeRates() async throws -> [CoinGeckoMarket]
}

public final class CoinGeckoNetworkManager: CryptoNetworkManager {
    private let baseUrl: String
    private let client: NetworkClient
    private let pageCount: Int
    private let perPage: Int

    /// `pageCount * perPage` caps how many coins are pulled, top-ranked by
    /// market cap. The default (4 pages × 250 = top 1000) stays comfortably
    /// within CoinGecko's free tier given `CurrencyService`'s 300s cache.
    /// `perPage` must stay ≤ 250 (the endpoint's maximum).
    public init(
        baseUrl: String = "https://api.coingecko.com",
        client: NetworkClient = URLSessionNetworkClient(),
        pageCount: Int = 4,
        perPage: Int = 250
    ) {
        self.baseUrl = baseUrl
        self.client = client
        self.pageCount = pageCount
        self.perPage = perPage
    }

    public func getExchangeRates() async throws -> [CoinGeckoMarket] {
        var markets: [CoinGeckoMarket] = []
        // Paginate sequentially (gentler on the free-tier rate limit than firing
        // every page at once).
        for page in 1...max(pageCount, 1) {
            let pageMarkets: [CoinGeckoMarket]
            do {
                pageMarkets = try await client.get(
                    baseURL: baseUrl,
                    path: "/api/v3/coins/markets",
                    queryItems: [
                        URLQueryItem(name: "vs_currency", value: "usd"),
                        URLQueryItem(name: "order", value: "market_cap_desc"),
                        URLQueryItem(name: "per_page", value: String(perPage)),
                        URLQueryItem(name: "page", value: String(page)),
                        URLQueryItem(name: "sparkline", value: "false")
                    ],
                    as: [CoinGeckoMarket].self
                )
            } catch {
                // Tolerate a failed *later* page (e.g. a rate-limited 429): keep
                // the coins already fetched instead of discarding the whole
                // refresh. A failed first page is fatal — with zero crypto we'd
                // rather surface the error and keep the previous cached snapshot.
                if markets.isEmpty { throw error }
                break
            }
            markets.append(contentsOf: pageMarkets)
            // A short page means we've reached the end of the listing — stop.
            if pageMarkets.count < perPage { break }
        }
        return markets
    }
}
