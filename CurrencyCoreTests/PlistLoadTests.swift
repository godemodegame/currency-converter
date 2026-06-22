//
//  PlistLoadTests.swift
//  CurrencyCoreTests
//
//  `Plist.load` decodes the bundled `{ currencies: [T] }` metadata; tests use a
//  fixture in this bundle and exercise the missing-file error path.
//

import Foundation
import Testing
@testable import CurrencyCore

/// Anchor for resolving this test bundle (Swift Testing has no XCTestCase).
private final class BundleToken {}

@Suite struct PlistLoadTests {
    private var testBundle: Bundle { Bundle(for: BundleToken.self) }

    @Test func loadsCurrenciesFromFixture() throws {
        let plist = try Plist<CurrencyInfo>.load(resource: "TestCurrencies", in: testBundle)
        #expect(plist.currencies.count == 2)
        let usd = plist.currencies.first { $0.code == "USD" }
        #expect(usd?.name == "US Dollar")
        #expect(usd?.country == "US")
    }

    @Test func missingResourceThrowsMissingPlistFile() {
        #expect(throws: CurrencyError.self) {
            _ = try Plist<CurrencyInfo>.load(resource: "DoesNotExist", in: testBundle)
        }
    }

    @Test func missingResourceThrowsSpecificCase() {
        do {
            _ = try Plist<CurrencyInfo>.load(resource: "DoesNotExist", in: testBundle)
            Issue.record("expected a throw")
        } catch CurrencyError.missingPlistFile {
            // expected
        } catch {
            Issue.record("unexpected error: \(error)")
        }
    }
}
