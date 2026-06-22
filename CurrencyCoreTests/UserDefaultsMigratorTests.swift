//
//  UserDefaultsMigratorTests.swift
//  CurrencyCoreTests
//
//  The legacy -> app-group migration must be idempotent and never clobber newer
//  shared data. Both stores are injected ephemeral suites.
//

import Foundation
import Testing
@testable import CurrencyCore

@Suite struct UserDefaultsMigratorTests {
    let savedKey = UserDefaultsKey.savedCurrencies
    let favKey = UserDefaultsKey.favoriteCurrencies

    private func makePair() -> (legacy: UserDefaults, shared: UserDefaults, cleanup: () -> Void) {
        let (legacy, legacyName) = makeEphemeralDefaults()
        let (shared, sharedName) = makeEphemeralDefaults()
        return (legacy, shared, {
            legacy.removePersistentDomain(forName: legacyName)
            shared.removePersistentDomain(forName: sharedName)
        })
    }

    @Test func copiesBothKeysWhenSharedEmpty() {
        let (legacy, shared, cleanup) = makePair()
        defer { cleanup() }

        let savedData = Data("[]".utf8)
        legacy.set(savedData, forKey: savedKey)
        legacy.set(["USD", "EUR"], forKey: favKey)

        UserDefaultsMigrator(legacy: legacy, shared: shared).migrateIfNeeded()

        #expect(shared.data(forKey: savedKey) == savedData)
        #expect(shared.array(forKey: favKey) as? [String] == ["USD", "EUR"])
        // Legacy keys cleared after a successful copy.
        #expect(legacy.data(forKey: savedKey) == nil)
        #expect(legacy.array(forKey: favKey) == nil)
    }

    @Test func doesNotClobberExistingSharedData() {
        let (legacy, shared, cleanup) = makePair()
        defer { cleanup() }

        legacy.set(Data("[1]".utf8), forKey: savedKey)
        legacy.set(["USD"], forKey: favKey)
        let sharedSaved = Data("[2]".utf8)
        shared.set(sharedSaved, forKey: savedKey)
        shared.set(["BTC"], forKey: favKey)

        UserDefaultsMigrator(legacy: legacy, shared: shared).migrateIfNeeded()

        // Newer shared values are preserved...
        #expect(shared.data(forKey: savedKey) == sharedSaved)
        #expect(shared.array(forKey: favKey) as? [String] == ["BTC"])
        // ...and the legacy values are left untouched (not cleared).
        #expect(legacy.data(forKey: savedKey) == Data("[1]".utf8))
        #expect(legacy.array(forKey: favKey) as? [String] == ["USD"])
    }

    @Test func noOpWhenLegacyEmpty() {
        let (legacy, shared, cleanup) = makePair()
        defer { cleanup() }

        UserDefaultsMigrator(legacy: legacy, shared: shared).migrateIfNeeded()

        #expect(shared.data(forKey: savedKey) == nil)
        #expect(shared.array(forKey: favKey) == nil)
    }

    @Test func ignoresEmptyLegacyFavorites() {
        let (legacy, shared, cleanup) = makePair()
        defer { cleanup() }

        legacy.set([String](), forKey: favKey)
        UserDefaultsMigrator(legacy: legacy, shared: shared).migrateIfNeeded()

        // Empty array is treated as nothing to migrate.
        #expect(shared.array(forKey: favKey) == nil)
    }

    @Test func isIdempotentAcrossRepeatedRuns() {
        let (legacy, shared, cleanup) = makePair()
        defer { cleanup() }

        legacy.set(Data("[]".utf8), forKey: savedKey)
        legacy.set(["USD"], forKey: favKey)

        let migrator = UserDefaultsMigrator(legacy: legacy, shared: shared)
        migrator.migrateIfNeeded()
        // Simulate the user changing shared data after the first migration.
        shared.set(["USD", "EUR"], forKey: favKey)
        migrator.migrateIfNeeded()

        // The second run must not resurrect the legacy value.
        #expect(shared.array(forKey: favKey) as? [String] == ["USD", "EUR"])
    }
}
