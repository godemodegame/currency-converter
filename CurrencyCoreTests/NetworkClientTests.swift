//
//  NetworkClientTests.swift
//  CurrencyCoreTests
//
//  URL building on the protocol extension (via a capturing mock) and the
//  real `URLSessionNetworkClient` status/decoding handling (via URLProtocol).
//

import Foundation
import Testing
@testable import CurrencyCore

@Suite struct NetworkClientURLBuildingTests {
    @Test func buildsURLWithPathAndPercentEncodedQuery() async throws {
        let mock = MockNetworkClient()
        mock.responseJSON = #"{"amount":1,"base":"USD","date":"2024-01-01","rates":{}}"#

        _ = try await mock.get(
            baseURL: "https://api.example.com",
            path: "/latest",
            queryItems: [URLQueryItem(name: "from", value: "A B")],
            as: ExchangeRatesResponse.self
        )

        let url = try #require(mock.capturedURL)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.host == "api.example.com")
        #expect(components.path == "/latest")
        // URLComponents percent-encodes the space; decoded back it round-trips.
        #expect(components.queryItems?.first { $0.name == "from" }?.value == "A B")
        #expect(url.absoluteString.contains("A%20B"))
    }

    @Test func invalidBaseURLThrows() async {
        let mock = MockNetworkClient()
        await #expect(throws: CurrencyError.self) {
            _ = try await mock.get(baseURL: "ht tp://bad url", path: "/x", as: ExchangeRatesResponse.self)
        }
    }
}

// `.serialized`: these share `URLProtocolStub`'s static stub state, so they must
// not run concurrently with each other.
@Suite(.serialized) struct URLSessionNetworkClientTests {
    @Test func decodesSuccessfulResponse() async throws {
        URLProtocolStub.reset()
        defer { URLProtocolStub.reset() }
        URLProtocolStub.statusCode = 200
        URLProtocolStub.responseData = Data(#"{"amount":1,"base":"USD","date":"2024-01-01","rates":{"EUR":0.92}}"#.utf8)

        let client = URLProtocolStub.makeClient()
        let result = try await client.get(URL(string: "https://example.com/latest")!, as: ExchangeRatesResponse.self)

        #expect(result.base == "USD")
        #expect(isApprox(result.rates["EUR"] ?? 0, 0.92))
    }

    @Test func nonSuccessStatusThrowsHTTPStatus() async {
        URLProtocolStub.reset()
        defer { URLProtocolStub.reset() }
        URLProtocolStub.statusCode = 503

        let client = URLProtocolStub.makeClient()
        do {
            _ = try await client.get(URL(string: "https://example.com")!, as: ExchangeRatesResponse.self)
            Issue.record("expected a throw")
        } catch CurrencyError.httpStatus(let code) {
            #expect(code == 503)
        } catch {
            Issue.record("unexpected error: \(error)")
        }
    }

    @Test func malformedBodyThrowsDecodingFailed() async {
        URLProtocolStub.reset()
        defer { URLProtocolStub.reset() }
        URLProtocolStub.statusCode = 200
        URLProtocolStub.responseData = Data("definitely not json".utf8)

        let client = URLProtocolStub.makeClient()
        do {
            _ = try await client.get(URL(string: "https://example.com")!, as: ExchangeRatesResponse.self)
            Issue.record("expected a throw")
        } catch CurrencyError.decodingFailed {
            // expected
        } catch {
            Issue.record("unexpected error: \(error)")
        }
    }
}
