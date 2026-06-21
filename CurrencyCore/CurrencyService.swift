//
//  CurrencyService.swift
//  CurrencyCore
//
//  Created by Kirill Kirilenko on 29/04/2023.
//

import Foundation

public protocol CurrencyServiceProtocol: AnyObject, ObservableObject {
    /// Returns the full currency list, every rate expressed against a single
    /// canonical base. Re-express against a user-selected currency on the
    /// client with `Currency.converted(against:)`.
    func getCurrencies() async throws -> [Currency]
    func getSavedCurrencies() async -> [Currency]
}

public actor CurrencyService: CurrencyServiceProtocol {
    // MARK: Private properties

    private let fiatNetworkManager: FiatNetworkManager
    private let fiatWorker: FiatCurrencyWorker
    private let cryptoNetworkManager: CryptoNetworkManager
    private let cryptoWorker: CryptoCurrencyWorker

    /// Every rate is fetched against this single canonical base. Callers
    /// re-express the list against any user-selected currency on the client
    /// via `Currency.converted(against:)`, which is exact because all rates
    /// share this base. Fetching against a different base is intentionally
    /// unsupported: the crypto source is always priced in USD, so a mixed
    /// base would yield inconsistent cross-rates.
    private let canonicalBase = "USD"

    /// How long an in-memory snapshot stays fresh before the next call refetches.
    private let cacheTTL: TimeInterval
    private var currencies: [Currency] = []
    private var lastFetch: Date?

    @CodableUserDefault(UserDefaultsKey.savedCurrencies, defaultValue: [])
    private var savedCurrencies: [Currency]

    // MARK: Lifecycle
    public init(
        fiatNetworkManager: FiatNetworkManager = FiatNetwork(),
        fiatWorker: FiatCurrencyWorker = FiatWorker(),
        cryptoNetworkManager: CryptoNetworkManager = CoinGeckoNetworkManager(),
        cryptoWorker: CryptoCurrencyWorker = CryptoWorker(),
        migrator: UserDefaultsMigrator = UserDefaultsMigrator(),
        cacheTTL: TimeInterval = 300
    ) {
        self.fiatNetworkManager = fiatNetworkManager
        self.fiatWorker = fiatWorker
        self.cryptoNetworkManager = cryptoNetworkManager
        self.cryptoWorker = cryptoWorker
        self.cacheTTL = cacheTTL
        migrator.migrateIfNeeded()
    }

    // MARK: - CurrencyServiceProtocol

    public func getSavedCurrencies() async -> [Currency] {
        savedCurrencies
    }

    public func getCurrencies() async throws -> [Currency] {
        if let lastFetch,
           !currencies.isEmpty,
           Date().timeIntervalSince(lastFetch) < cacheTTL {
            return currencies
        }

        // Fetch both sources concurrently; the call fails atomically if either
        // source throws, leaving the previous cache/persisted snapshot intact.
        async let fiatResponse = fiatNetworkManager.getExchangeRates(currencyCode: canonicalBase)
        async let cryptoResponse = cryptoNetworkManager.getExchangeRates()

        let fiat = try fiatWorker.prepareCurrencies(try await fiatResponse)
        let crypto = try cryptoWorker.prepareCurrencies(try await cryptoResponse)

        let combined = (fiat + crypto).sorted { $0.code < $1.code }
        currencies = combined
        lastFetch = Date()
        savedCurrencies = combined
        return combined
    }
}
