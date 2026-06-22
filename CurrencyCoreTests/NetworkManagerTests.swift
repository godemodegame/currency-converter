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
    @Test func requestsSimplePriceWithIdsAndVsCurrency() async throws {
        let mock = MockNetworkClient()
        mock.responseJSON = #"{"bitcoin":{"usd":50000}}"#
        let sut = CoinGeckoNetworkManager(baseUrl: "https://crypto.example.com", client: mock)

        let response = try await sut.getExchangeRates()

        #expect(response["bitcoin"] != nil)
        let url = try #require(mock.capturedURL)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.host == "crypto.example.com")
        #expect(components.path == "/api/v3/simple/price")
        #expect(components.queryItems?.first { $0.name == "vs_currencies" }?.value == "usd")
        let ids = components.queryItems?.first { $0.name == "ids" }?.value ?? ""
        #expect(ids.contains("bitcoin"))
        #expect(ids.contains("ethereum"))
    }

    @Test func requestsEveryMappedCoinId() async throws {
        let mock = MockNetworkClient()
        mock.responseJSON = "{}"
        let sut = CoinGeckoNetworkManager(baseUrl: "https://crypto.example.com", client: mock)

        _ = try await sut.getExchangeRates()

        let url = try #require(mock.capturedURL)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let ids = components.queryItems?.first { $0.name == "ids" }?.value ?? ""
        let requested = Set(ids.split(separator: ",").map(String.init))
        // Every coin in the canonical map must appear in the request — guards
        // against a coin silently dropping out when CoinMapping is edited.
        #expect(requested == Set(CoinMapping.appCodeToCoinGeckoId.values))
    }
}
