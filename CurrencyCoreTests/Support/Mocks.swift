//
//  Mocks.swift
//  CurrencyCoreTests
//
//  Shared test doubles and helpers for the CurrencyCore logic tests.
//

import Foundation
@testable import CurrencyCore

// MARK: - Builders

/// Builds a `Currency` with sensible defaults so tests only specify what matters.
func makeCurrency(
    _ code: String,
    rate: Double = 1,
    type: CurrencyType = .fiat,
    name: String? = nil,
    imageSource: ImageSource = .flag("🏳️")
) -> Currency {
    Currency(name: name ?? code, imageSource: imageSource, code: code, rate: rate, type: type)
}

func decodeJSON<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
    try JSONDecoder().decode(T.self, from: Data(json.utf8))
}

/// A throwaway `UserDefaults` suite plus its name, so tests can wipe it in a `defer`.
func makeEphemeralDefaults() -> (defaults: UserDefaults, name: String) {
    let name = "test.\(UUID().uuidString)"
    return (UserDefaults(suiteName: name)!, name)
}

func isApprox(_ a: Double, _ b: Double, tolerance: Double = 1e-9) -> Bool {
    abs(a - b) <= tolerance
}

// MARK: - NetworkClient double

/// Captures requested URLs and replays a canned JSON body (or an error), so the
/// URL-building convenience and the network managers can be tested without I/O.
final class MockNetworkClient: NetworkClient, @unchecked Sendable {
    private(set) var capturedURLs: [URL] = []
    var capturedURL: URL? { capturedURLs.last }
    var responseJSON: String = "{}"
    var error: Error?

    func get<T>(_ url: URL, as type: T.Type) async throws -> T where T: Decodable {
        capturedURLs.append(url)
        if let error { throw error }
        return try JSONDecoder().decode(T.self, from: Data(responseJSON.utf8))
    }
}

// MARK: - URLProtocol stub (for URLSessionNetworkClient)

/// A `URLProtocol` that returns a canned response/status (or fails), letting the
/// real `URLSessionNetworkClient` be exercised over an ephemeral session.
final class URLProtocolStub: URLProtocol {
    nonisolated(unsafe) static var responseData = Data()
    nonisolated(unsafe) static var statusCode = 200
    nonisolated(unsafe) static var failure: Error?
    nonisolated(unsafe) static var lastRequestURL: URL?

    static func reset() {
        responseData = Data()
        statusCode = 200
        failure = nil
        lastRequestURL = nil
    }

    static func makeClient() -> URLSessionNetworkClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        return URLSessionNetworkClient(session: URLSession(configuration: config))
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lastRequestURL = request.url
        if let failure = Self.failure {
            client?.urlProtocol(self, didFailWithError: failure)
            return
        }
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: Self.statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.responseData)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

// MARK: - CurrencyService dependency doubles

final class MockFiatNetwork: FiatNetworkManager, @unchecked Sendable {
    private(set) var callCount = 0
    private(set) var lastCurrencyCode: String?
    var error: Error?
    var response: ExchangeRatesResponse

    init(response: ExchangeRatesResponse = ExchangeRatesResponse(amount: 1, base: "USD", date: "", rates: [:])) {
        self.response = response
    }

    func getExchangeRates(currencyCode: String) async throws -> ExchangeRatesResponse {
        callCount += 1
        lastCurrencyCode = currencyCode
        if let error { throw error }
        return response
    }
}

final class MockCryptoNetwork: CryptoNetworkManager, @unchecked Sendable {
    private(set) var callCount = 0
    var error: Error?
    var response: [String: CoinGeckoResponse]

    init(response: [String: CoinGeckoResponse] = [:]) { self.response = response }

    func getExchangeRates() async throws -> [String: CoinGeckoResponse] {
        callCount += 1
        if let error { throw error }
        return response
    }
}

final class MockFiatWorker: FiatCurrencyWorker {
    var currencies: [Currency]
    init(currencies: [Currency]) { self.currencies = currencies }
    func prepareCurrencies(_ dict: ExchangeRatesResponse) throws -> [Currency] { currencies }
}

final class MockCryptoWorker: CryptoCurrencyWorker {
    var currencies: [Currency]
    init(currencies: [Currency]) { self.currencies = currencies }
    func prepareCurrencies(_ dict: [String: CoinGeckoResponse]) throws -> [Currency] { currencies }
}
