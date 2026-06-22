//
//  PropertyWrapperTests.swift
//  CurrencyCoreTests
//
//  `@UserDefault` (native values) and `@CodableUserDefault` (JSON Data) over an
//  injected ephemeral suite — no global state touched.
//

import Foundation
import Testing
@testable import CurrencyCore

@Suite struct UserDefaultWrapperTests {
    @Test func returnsDefaultWhenAbsent() {
        let (defaults, name) = makeEphemeralDefaults()
        defer { defaults.removePersistentDomain(forName: name) }

        let wrapper = UserDefault("missing", defaultValue: ["USD"], userDefaults: defaults)
        #expect(wrapper.wrappedValue == ["USD"])
    }

    @Test func persistsAndReadsStringArray() {
        let (defaults, name) = makeEphemeralDefaults()
        defer { defaults.removePersistentDomain(forName: name) }

        var wrapper = UserDefault("favs", defaultValue: [String](), userDefaults: defaults)
        wrapper.wrappedValue = ["USD", "EUR"]
        #expect(wrapper.wrappedValue == ["USD", "EUR"])
        // The value is stored natively, not as JSON Data.
        #expect(defaults.array(forKey: "favs") as? [String] == ["USD", "EUR"])
    }

    @Test func persistsPrimitive() {
        let (defaults, name) = makeEphemeralDefaults()
        defer { defaults.removePersistentDomain(forName: name) }

        var wrapper = UserDefault("count", defaultValue: 0, userDefaults: defaults)
        wrapper.wrappedValue = 42
        #expect(wrapper.wrappedValue == 42)
    }
}

@Suite struct CodableUserDefaultTests {
    @Test func returnsDefaultWhenAbsent() {
        let (defaults, name) = makeEphemeralDefaults()
        defer { defaults.removePersistentDomain(forName: name) }

        let wrapper = CodableUserDefault(UserDefaultsKey.savedCurrencies, defaultValue: [Currency](), userDefaults: defaults)
        #expect(wrapper.wrappedValue.isEmpty)
    }

    @Test func encodesAndDecodesCurrencies() {
        let (defaults, name) = makeEphemeralDefaults()
        defer { defaults.removePersistentDomain(forName: name) }

        let list = [makeCurrency("USD"), makeCurrency("BTC", rate: 0.00002, type: .crypto)]
        var wrapper = CodableUserDefault("saved", defaultValue: [Currency](), userDefaults: defaults)
        wrapper.wrappedValue = list

        // Stored as JSON Data, not a native array.
        #expect(defaults.data(forKey: "saved") != nil)
        let read = wrapper.wrappedValue
        #expect(read.map(\.code) == ["USD", "BTC"])
        #expect(read.last?.type == .crypto)
    }

    @Test func corruptDataFallsBackToDefault() {
        let (defaults, name) = makeEphemeralDefaults()
        defer { defaults.removePersistentDomain(forName: name) }

        defaults.set(Data("not json".utf8), forKey: "saved")
        let wrapper = CodableUserDefault("saved", defaultValue: [makeCurrency("USD")], userDefaults: defaults)
        #expect(wrapper.wrappedValue.map(\.code) == ["USD"])
    }
}
