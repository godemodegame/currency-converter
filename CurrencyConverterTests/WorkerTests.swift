//
//  WorkerTests.swift
//  CurrencyConverterTests
//
//  The fiat/crypto workers enrich raw rates with metadata loaded from the
//  bundled `*.plist` files via `Bundle.main`. Those plists ship in the *app*
//  bundle, so these tests must run app-hosted (where `Bundle.main` is the app).
//

import Testing
import CurrencyCore

@Suite struct FiatWorkerTests {
    @Test func enrichesRatesAndFoldsInBaseCurrency() throws {
        let response = try decodeJSON(
            ExchangeRatesResponse.self,
            #"{"amount":1,"base":"USD","date":"2024-01-01","rates":{"EUR":0.92}}"#
        )
        let result = try FiatWorker().prepareCurrencies(response)

        // Frankfurter omits the base; the worker folds USD back in at `amount`.
        let usd = try #require(result.first { $0.code == "USD" })
        #expect(isApprox(usd.rate, 1))
        #expect(usd.type == .fiat)
        #expect(!usd.name.isEmpty)
        if case .flag(let flag) = usd.imageSource {
            #expect(!flag.isEmpty)
        } else {
            Issue.record("fiat currency should use a flag image source")
        }

        // EUR enriched with name + flag from the bundled plist.
        let eur = try #require(result.first { $0.code == "EUR" })
        #expect(isApprox(eur.rate, 0.92))
        #expect(!eur.name.isEmpty)
    }

    @Test func filtersOutCodesMissingFromPlist() throws {
        let response = try decodeJSON(
            ExchangeRatesResponse.self,
            #"{"amount":1,"base":"USD","date":"2024-01-01","rates":{"ZZZ":1.23}}"#
        )
        let result = try FiatWorker().prepareCurrencies(response)

        // ZZZ has no metadata (empty name/flag) → filtered out.
        #expect(result.first { $0.code == "ZZZ" } == nil)
        // The base currency still survives.
        #expect(result.contains { $0.code == "USD" })
    }
}

@Suite struct CryptoWorkerTests {
    @Test func mapsGeckoIdToCodeAndInvertsRate() throws {
        let dict = try decodeJSON([String: CoinGeckoResponse].self, #"{"bitcoin":{"usd":50000}}"#)
        let result = try CryptoWorker().prepareCurrencies(dict)

        let btc = try #require(result.first { $0.code == "BTC" })
        #expect(btc.type == .crypto)
        // USD-priced rate is inverted to "units per USD".
        #expect(isApprox(btc.rate, 1.0 / 50000))
        if case .image = btc.imageSource {
            // expected
        } else {
            Issue.record("crypto currency should use a remote image source")
        }
    }

    @Test func dropsUnknownCoinIds() throws {
        let dict = try decodeJSON(
            [String: CoinGeckoResponse].self,
            #"{"bitcoin":{"usd":50000},"made-up-coin":{"usd":1}}"#
        )
        let result = try CryptoWorker().prepareCurrencies(dict)

        #expect(result.contains { $0.code == "BTC" })
        // "made-up-coin" has no app-code mapping → dropped.
        #expect(result.count == 1)
    }
}
