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

    @StateObject
    private var purchaseService = PurchaseService(productsId: ["annual.ocean.plus"])
    private let currencyService = CurrencyService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(ConverterViewModel(currencyService: currencyService))
                .environmentObject(
                    CurrenciesListViewModel(
                        currencyService: currencyService,
                        purchaseService: purchaseService
                    )
                )
                .environmentObject(purchaseService)
                .task {
                    await purchaseService.updatePurchasedProducts()
                    await purchaseService.loadProducts()
                }
        }
    }
}
