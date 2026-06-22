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

    /// Persists the last-known list (read by the app on cold start and by the
    /// widget's config picker). File-backed in production so the now-~1000-item
    /// list doesn't bloat the shared UserDefaults suite.
    private let snapshotStore: CurrencySnapshotStore

    // MARK: Lifecycle
    public init(
        fiatNetworkManager: FiatNetworkManager = FiatNetwork(),
        fiatWorker: FiatCurrencyWorker = FiatWorker(),
        cryptoNetworkManager: CryptoNetworkManager = CoinGeckoNetworkManager(),
        cryptoWorker: CryptoCurrencyWorker = CryptoWorker(),
        snapshotStore: CurrencySnapshotStore = FileCurrencySnapshotStore(),
        migrator: UserDefaultsMigrator = UserDefaultsMigrator(),
        cacheTTL: TimeInterval = 300
    ) {
        self.fiatNetworkManager = fiatNetworkManager
        self.fiatWorker = fiatWorker
        self.cryptoNetworkManager = cryptoNetworkManager
        self.cryptoWorker = cryptoWorker
        self.snapshotStore = snapshotStore
        self.cacheTTL = cacheTTL
        migrator.migrateIfNeeded()
    }

    // MARK: - CurrencyServiceProtocol

    public func getSavedCurrencies() async -> [Currency] {
        snapshotStore.load()
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

        // Dedupe by code: `Currency.id` is the code, and the widened crypto set
        // can collide (two coins sharing a ticker, or a crypto ticker equal to a
        // fiat code). Fiat is listed first so it wins such a clash; among crypto,
        // market-cap order means the largest coin wins.
        var seenCodes = Set<String>()
        let combined = (fiat + crypto)
            .filter { seenCodes.insert($0.code).inserted }
            .sorted { $0.code < $1.code }
        currencies = combined
        lastFetch = Date()
        snapshotStore.save(combined)
        return combined
    }
}
