//
//  CodableModelTests.swift
//  CurrencyCoreTests
//
//  Codable behaviour for the persisted models (`savedCurrencies` round-trips
//  these through JSON), including `CurrencyType`'s reject-unknown decoder.
//

import Foundation
import Testing
@testable import CurrencyCore

@Suite struct CodableModelTests {
    @Test func currencyJSONRoundTrip() throws {
        let original = makeCurrency("BTC", rate: 0.00002, type: .crypto, name: "Bitcoin",
                                    imageSource: .image(URL(string: "https://example.com/btc.png")!))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Currency.self, from: data)

        #expect(decoded.code == original.code)
        #expect(decoded.name == original.name)
        #expect(decoded.type == original.type)
        #expect(isApprox(decoded.rate, original.rate))
        if case .image(let url) = decoded.imageSource {
            #expect(url.absoluteString == "https://example.com/btc.png")
        } else {
            Issue.record("expected .image, got \(decoded.imageSource)")
        }
    }

    @Test func currencyTypeDecodesKnownValues() throws {
        #expect(try decodeJSON(CurrencyType.self, "\"fiat\"") == .fiat)
        #expect(try decodeJSON(CurrencyType.self, "\"crypto\"") == .crypto)
    }

    @Test func currencyTypeRejectsUnknownValue() {
        #expect(throws: DecodingError.self) {
            _ = try decodeJSON(CurrencyType.self, "\"gold\"")
        }
    }

    @Test func imageSourceFlagRoundTrip() throws {
        let data = try JSONEncoder().encode(ImageSource.flag("🇺🇸"))
        let decoded = try JSONDecoder().decode(ImageSource.self, from: data)
        if case .flag(let value) = decoded {
            #expect(value == "🇺🇸")
        } else {
            Issue.record("expected .flag, got \(decoded)")
        }
    }

    @Test func imageSourceImageRoundTrip() throws {
        let url = URL(string: "https://example.com/eth.png")!
        let data = try JSONEncoder().encode(ImageSource.image(url))
        let decoded = try JSONDecoder().decode(ImageSource.self, from: data)
        if case .image(let value) = decoded {
            #expect(value == url)
        } else {
            Issue.record("expected .image, got \(decoded)")
        }
    }
}
