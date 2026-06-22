//
//  CurrencyMathTests.swift
//  CurrencyCoreTests
//
//  Pure conversion math on `Currency` — the heart of the app's correctness.
//

import Testing
@testable import CurrencyCore

@Suite struct CurrencyMathTests {
    // All rates are "units of this currency per 1 USD" (the canonical base).
    let usd = makeCurrency("USD", rate: 1)
    let eur = makeCurrency("EUR", rate: 0.92)
    let btc = makeCurrency("BTC", rate: 0.00002, type: .crypto)

    @Test func rateAgainstSelfIsAmount() {
        #expect(isApprox(usd.rate(against: usd), 1))
        #expect(isApprox(eur.rate(against: eur), 1))
        #expect(isApprox(eur.rate(against: eur, amount: 5), 5))
    }

    @Test func rateAgainstOtherBase() {
        // EUR per 1 USD == 0.92
        #expect(isApprox(eur.rate(against: usd), 0.92))
        // USD per 1 EUR == 1 / 0.92
        #expect(isApprox(usd.rate(against: eur), 1 / 0.92))
    }

    @Test func rateScalesWithAmount() {
        #expect(isApprox(eur.rate(against: usd, amount: 10), 9.2))
        #expect(isApprox(btc.rate(against: usd, amount: 100), 0.00002 * 100))
    }

    @Test func convertedReturnsCopyWithNewRateOnly() {
        let converted = eur.converted(against: usd, amount: 3)
        #expect(converted.code == eur.code)
        #expect(converted.name == eur.name)
        #expect(converted.type == eur.type)
        #expect(isApprox(converted.rate, 0.92 * 3))
    }

    @Test func sequenceConvertedReexpressesEveryElement() {
        let list = [usd, eur, btc]
        let converted = list.converted(against: eur, amount: 1)
        #expect(converted.count == 3)
        #expect(isApprox(converted.first { $0.code == "EUR" }!.rate, 1))
        #expect(isApprox(converted.first { $0.code == "USD" }!.rate, 1 / 0.92))
    }

    @Test func identifiableIdIsCode() {
        #expect(usd.id == "USD")
        #expect(btc.id == btc.code)
    }
}
