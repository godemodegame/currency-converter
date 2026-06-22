//
//  CoinMappingTests.swift
//  CurrencyCoreTests
//
//  The canonical app-code <-> CoinGecko-id map is the single source of truth for
//  crypto requests and decoding; drift here silently drops coins.
//

import Testing
@testable import CurrencyCore

@Suite struct CoinMappingTests {
    @Test func mappingIsBijective() {
        // The derived inverse traps at launch on duplicate ids; assert the counts
        // match so a no-op duplicate (same pair twice) can't sneak through either.
        #expect(CoinMapping.appCodeToCoinGeckoId.count == CoinMapping.coinGeckoIdToAppCode.count)
        let ids = CoinMapping.appCodeToCoinGeckoId.values
        #expect(Set(ids).count == ids.count, "CoinGecko ids must be unique")
    }

    @Test func inverseRoundTripsEveryPair() {
        for (code, id) in CoinMapping.appCodeToCoinGeckoId {
            #expect(CoinMapping.coinGeckoIdToAppCode[id] == code)
        }
    }

    @Test func knownPairsAreMapped() {
        #expect(CoinMapping.appCodeToCoinGeckoId["BTC"] == "bitcoin")
        #expect(CoinMapping.appCodeToCoinGeckoId["ETH"] == "ethereum")
        #expect(CoinMapping.coinGeckoIdToAppCode["solana"] == "SOL")
    }

    @Test func removedCoinIsAbsent() {
        // Toncoin (TON) was removed in 7ab8cee — guard against accidental re-add.
        #expect(CoinMapping.appCodeToCoinGeckoId["TON"] == nil)
        #expect(CoinMapping.coinGeckoIdToAppCode["the-open-network"] == nil)
    }
}
