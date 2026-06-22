//
//  MockCurrencyService.swift
//  CurrencyConverterTests
//
//  Drop-in `CurrencyServiceProtocol` for ViewModel tests: returns injected
//  lists / errors and counts calls, with no network or persistence.
//

import Foundation
import CurrencyCore

final class MockCurrencyService: CurrencyServiceProtocol {
    var savedCurrencies: [Currency]
    var freshCurrencies: [Currency]
    var error: Error?

    private(set) var getCurrenciesCallCount = 0
    private(set) var getSavedCurrenciesCallCount = 0

    init(saved: [Currency] = [], fresh: [Currency] = [], error: Error? = nil) {
        self.savedCurrencies = saved
        self.freshCurrencies = fresh
        self.error = error
    }

    func getCurrencies() async throws -> [Currency] {
        getCurrenciesCallCount += 1
        if let error { throw error }
        return freshCurrencies
    }

    func getSavedCurrencies() async -> [Currency] {
        getSavedCurrenciesCallCount += 1
        return savedCurrencies
    }
}
