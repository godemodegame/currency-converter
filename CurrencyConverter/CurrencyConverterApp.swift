//
//  CurrencyConverterApp.swift
//  CurrencyConverter
//
//  Created by Kirill Kirilenko on 29/04/2023.
//

import CurrencyCore
import StoreKit
import SwiftUI
import Subscriptions

@main
struct CurrencyConverterApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // The view models are owned as `@StateObject` so they're created exactly
    // once. Constructing them inline in `body` (e.g. `.environmentObject(
    // ConverterViewModel(...))`) rebuilds a fresh, empty instance on every
    // `body` re-evaluation — and `purchaseService`'s `.task` completing forces
    // one — which can blank out the already-loaded converter/list.
    @StateObject private var purchaseService: PurchaseService
    @StateObject private var converterViewModel: ConverterViewModel
    @StateObject private var listViewModel: CurrenciesListViewModel

    init() {
        // No-op outside UI-test mode; seeds deterministic launch state otherwise.
        UITestConfig.bootstrapIfNeeded()
        // Swap in a network-free fixture source when running UI tests.
        let currencyService: any CurrencyServiceProtocol = UITestConfig.isActive
            ? UITestStubCurrencyService()
            : CurrencyService()
        let purchaseService = PurchaseService(productsId: ["annual.ocean.plus"])

        _purchaseService = StateObject(wrappedValue: purchaseService)
        _converterViewModel = StateObject(
            wrappedValue: ConverterViewModel(currencyService: currencyService)
        )
        _listViewModel = StateObject(
            wrappedValue: CurrenciesListViewModel(
                currencyService: currencyService,
                purchaseService: purchaseService
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(converterViewModel)
                .environmentObject(listViewModel)
                .environmentObject(purchaseService)
                .task {
                    await purchaseService.updatePurchasedProducts()
                    await purchaseService.loadProducts()
                }
        }
    }
}
