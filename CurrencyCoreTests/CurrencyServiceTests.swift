//
//  CurrencyServiceTests.swift
//  CurrencyCoreTests
//
//  The actor's aggregation, TTL caching, atomic failure, and persistence — all
//  with injected mock workers/managers (no network, no plists) and an in-memory
//  snapshot store, so the suite touches no shared storage and needn't serialize.
//

import Foundation
import Testing
@testable import CurrencyCore

@Suite struct CurrencyServiceTests {
    private func makeService(
        fiat: [Currency],
        crypto: [Currency],
        cacheTTL: TimeInterval = 300,
        cryptoError: Error? = nil,
        store: MockSnapshotStore = MockSnapshotStore()
    ) -> (service: CurrencyService, fiatNet: MockFiatNetwork, cryptoNet: MockCryptoNetwork, store: MockSnapshotStore) {
        let fiatNet = MockFiatNetwork()
        let cryptoNet = MockCryptoNetwork()
        cryptoNet.error = cryptoError
        // Ephemeral migrator so init never touches real .standard / shared defaults.
        let (legacy, _) = makeEphemeralDefaults()
        let (shared, _) = makeEphemeralDefaults()
        let service = CurrencyService(
            fiatNetworkManager: fiatNet,
            fiatWorker: MockFiatWorker(currencies: fiat),
            cryptoNetworkManager: cryptoNet,
            cryptoWorker: MockCryptoWorker(currencies: crypto),
            snapshotStore: store,
            migrator: UserDefaultsMigrator(legacy: legacy, shared: shared),
            cacheTTL: cacheTTL
        )
        return (service, fiatNet, cryptoNet, store)
    }

    @Test func combinesAndSortsByCode() async throws {
        let (service, _, _, _) = makeService(
            fiat: [makeCurrency("USD"), makeCurrency("EUR")],
            crypto: [makeCurrency("BTC", type: .crypto)]
        )
        let result = try await service.getCurrencies()
        #expect(result.map(\.code) == ["BTC", "EUR", "USD"])
    }

    @Test func fetchesFiatAgainstCanonicalUSDBase() async throws {
        let (service, fiatNet, _, _) = makeService(fiat: [makeCurrency("USD")], crypto: [])
        _ = try await service.getCurrencies()
        #expect(fiatNet.lastCurrencyCode == "USD")
    }

    @Test func servesFromCacheWithinTTL() async throws {
        let (service, fiatNet, cryptoNet, _) = makeService(
            fiat: [makeCurrency("USD")], crypto: [], cacheTTL: 300
        )
        _ = try await service.getCurrencies()
        _ = try await service.getCurrencies()
        #expect(fiatNet.callCount == 1)
        #expect(cryptoNet.callCount == 1)
    }

    @Test func refetchesAfterTTLExpiry() async throws {
        let (service, fiatNet, _, _) = makeService(
            fiat: [makeCurrency("USD")], crypto: [], cacheTTL: 0
        )
        _ = try await service.getCurrencies()
        _ = try await service.getCurrencies()
        #expect(fiatNet.callCount == 2)
    }

    @Test func failsAtomicallyWithoutTouchingPersistedSnapshot() async throws {
        // Seed a known persisted snapshot in the injected store.
        let store = MockSnapshotStore([makeCurrency("USD")])
        let (service, _, _, _) = makeService(
            fiat: [makeCurrency("EUR")],
            crypto: [makeCurrency("BTC", type: .crypto)],
            cryptoError: CurrencyError.invalidResponse,
            store: store
        )

        await #expect(throws: CurrencyError.self) {
            _ = try await service.getCurrencies()
        }
        // Previous persisted snapshot is intact.
        let saved = await service.getSavedCurrencies()
        #expect(saved.map(\.code) == ["USD"])
    }

    @Test func persistsCombinedListAfterFetch() async throws {
        let (service, _, _, _) = makeService(
            fiat: [makeCurrency("USD"), makeCurrency("EUR")],
            crypto: [makeCurrency("BTC", type: .crypto)]
        )
        _ = try await service.getCurrencies()
        // getSavedCurrencies reads back through the persistence layer.
        let saved = await service.getSavedCurrencies()
        #expect(saved.map(\.code) == ["BTC", "EUR", "USD"])
    }

    @Test func persistedSnapshotIsVisibleToANewInstance() async throws {
        // The widget runs in a separate process and reads the persisted snapshot,
        // so a brand-new service must see what a prior one persisted. A shared
        // store stands in for the shared on-disk file.
        let store = MockSnapshotStore()
        let (writer, _, _, _) = makeService(
            fiat: [makeCurrency("USD"), makeCurrency("EUR")],
            crypto: [makeCurrency("BTC", type: .crypto)],
            store: store
        )
        _ = try await writer.getCurrencies()

        let (reader, _, _, _) = makeService(fiat: [], crypto: [], store: store)
        let saved = await reader.getSavedCurrencies()
        #expect(saved.map(\.code) == ["BTC", "EUR", "USD"])
    }

    @Test func getSavedCurrenciesReturnsPersistedValue() async throws {
        let store = MockSnapshotStore([makeCurrency("JPY"), makeCurrency("GBP")])
        let (service, _, _, _) = makeService(fiat: [], crypto: [], store: store)
        let saved = await service.getSavedCurrencies()
        #expect(Set(saved.map(\.code)) == ["JPY", "GBP"])
    }
}
