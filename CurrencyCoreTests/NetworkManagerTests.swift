//
//  NetworkManagerTests.swift
//  CurrencyCoreTests
//
//  The fiat/crypto network managers just assemble a request and decode it; a
//  capturing `MockNetworkClient` verifies the endpoints and query parameters.
//

import Foundation
import Testing
@testable import CurrencyCore

@Suite struct FiatNetworkTests {
    @Test func requestsLatestWithFromQuery() async throws {
        let mock = MockNetworkClient()
        mock.responseJSON = #"{"amount":1,"base":"USD","date":"2024-01-01","rates":{"EUR":0.92}}"#
        let sut = FiatNetwork(baseUrl: "https://fiat.example.com", client: mock)

        let response = try await sut.getExchangeRates(currencyCode: "USD")

        #expect(response.base == "USD")
        let url = try #require(mock.capturedURL)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.host == "fiat.example.com")
        #expect(components.path == "/latest")
        #expect(components.queryItems?.first { $0.name == "from" }?.value == "USD")
    }
}

@Suite struct CoinGeckoNetworkTests {
    /// A single market row keyed to `perPage = 1`, so a one-element page is a
    /// *full* page (won't trip the short-page early-out) and pagination keeps going.
    private static let oneMarketJSON =
        #"[{"symbol":"btc","name":"Bitcoin","image":"https://x/btc.png","current_price":50000}]"#

    @Test func requestsMarketsEndpointRankedByMarketCap() async throws {
        let mock = MockNetworkClient()
        mock.responseJSON = Self.oneMarketJSON
        let sut = CoinGeckoNetworkManager(
            baseUrl: "https://crypto.example.com", client: mock, pageCount: 1, perPage: 250
        )

        let response = try await sut.getExchangeRates()

        #expect(response.first?.symbol == "btc")
        #expect(isApprox(response.first?.currentPrice ?? 0, 50000))
        let url = try #require(mock.capturedURL)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.host == "crypto.example.com")
        #expect(components.path == "/api/v3/coins/markets")
        #expect(components.queryItems?.first { $0.name == "vs_currency" }?.value == "usd")
        #expect(components.queryItems?.first { $0.name == "order" }?.value == "market_cap_desc")
        #expect(components.queryItems?.first { $0.name == "per_page" }?.value == "250")
        #expect(components.queryItems?.first { $0.name == "page" }?.value == "1")
    }

    @Test func paginatesUpToPageCountRequestingEachPage() async throws {
        let mock = MockNetworkClient()
        mock.responseJSON = Self.oneMarketJSON // full page at perPage = 1 → never short
        let sut = CoinGeckoNetworkManager(
            baseUrl: "https://crypto.example.com", client: mock, pageCount: 3, perPage: 1
        )

        let response = try await sut.getExchangeRates()

        #expect(response.count == 3) // one row accumulated per page
        let pages = mock.capturedURLs.compactMap { url in
            URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first { $0.name == "page" }?.value
        }
        #expect(pages == ["1", "2", "3"])
    }

    @Test func stopsEarlyOnShortPage() async throws {
        let mock = MockNetworkClient()
        // One row but perPage = 2 → short page → stop after the first request.
        mock.responseJSON = Self.oneMarketJSON
        let sut = CoinGeckoNetworkManager(
            baseUrl: "https://crypto.example.com", client: mock, pageCount: 4, perPage: 2
        )

        _ = try await sut.getExchangeRates()

        #expect(mock.capturedURLs.count == 1)
    }

    @Test func keepsEarlierPagesWhenALaterPageFails() async throws {
        let mock = MockNetworkClient()
        mock.responseJSON = Self.oneMarketJSON // full page at perPage = 1
        mock.failOnCall = 2                     // page 2 gets rate-limited
        let sut = CoinGeckoNetworkManager(
            baseUrl: "https://crypto.example.com", client: mock, pageCount: 4, perPage: 1
        )

        let response = try await sut.getExchangeRates()

        // Page 1 survived; the 429 on page 2 ended pagination without throwing.
        #expect(response.count == 1)
        #expect(mock.capturedURLs.count == 2)
    }

    @Test func firstPageFailureIsFatal() async throws {
        let mock = MockNetworkClient()
        mock.responseJSON = Self.oneMarketJSON
        mock.failOnCall = 1 // nothing fetched yet → must surface the error
        let sut = CoinGeckoNetworkManager(
            baseUrl: "https://crypto.example.com", client: mock, pageCount: 4, perPage: 1
        )

        await #expect(throws: CurrencyError.self) {
            _ = try await sut.getExchangeRates()
        }
    }
}
