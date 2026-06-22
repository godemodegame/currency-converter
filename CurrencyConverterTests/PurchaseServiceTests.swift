//
//  PurchaseServiceTests.swift
//  CurrencyConverterTests
//
//  Coverage of the parts of the IAP gate that don't require a StoreKit test
//  environment. The pro-unlocked path (`purchasedProductIDs` is `private(set)`)
//  and the purchase/restore flows are documented out-of-scope here.
//

import Testing
import Subscriptions

@Suite @MainActor struct PurchaseServiceTests {
    @Test func defaultsToLocked() {
        let service = PurchaseService(productsId: ["annual.ocean.plus"])
        #expect(!service.hasUnlockedPro)
        #expect(service.purchasedProductIDs.isEmpty)
    }

    @Test func purchaseErrorCasesAreDistinct() {
        let cancelled = PurchaseError.cancelled
        if case .cancelled = cancelled {
            // expected
        } else {
            Issue.record("expected .cancelled")
        }

        let unverified = PurchaseError.unverified(CancellationError())
        if case .unverified = unverified {
            // expected
        } else {
            Issue.record("expected .unverified")
        }
    }
}
