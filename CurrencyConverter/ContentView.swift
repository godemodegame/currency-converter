//
//  ContentView.swift
//  CurrencyConverter
//
//  Created by Kirill Kirilenko on 29/04/2023.
//

import FirebaseAnalytics
import GoogleMobileAds
import CurrencyCore
import SwiftUI
import Subscriptions

struct ContentView: View {
    @AppStorage("isFirstOpen") var isFirstOpen = true
    @EnvironmentObject var purchaseService: PurchaseService
    @State var showOnboarding = false
    @State var showSubscription = false

    var body: some View {
        NavigationView {
            ConverterView()
                .navigationTitle("Rates")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink {
                            CurrenciesList()
                        } label: {
                            Text("Add")
                        }
                    }

                    ToolbarItem(placement: .navigationBarLeading) {
                        if !purchaseService.hasUnlockedPro {
                            Button {
                                showSubscription.toggle()
                            } label: {
                                Text("Remove ads")
                            }
                        }
                    }
                }.sheet(isPresented: $showOnboarding) {
                    Onboarding()
                }.sheet(isPresented: $showSubscription) {
                        SubscriptionView()
                }.onAppear {
                    Analytics.logEvent("open app", parameters: [:])
                    if isFirstOpen {
                        showOnboarding.toggle()
                        UserDefaults(
                            suiteName: "group.gmg.CurrencyConverter"
                        )?.set(
                            ["USD", "EUR", "BTC"],
                            forKey: "favoriteCurrencies"
                        )
                    }
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static let currencyService = CurrencyService()
    static let purchaseService = PurchaseService(productsId: ["annual.ocean.plus"])

    static var previews: some View {
        ContentView()
            .environmentObject(ConverterViewModel(currencyService: currencyService))
            .environmentObject(
                CurrenciesListViewModel(
                    currencyService: currencyService,
                    purchaseService: purchaseService
                )
            )
            .environmentObject(purchaseService)
            .onAppear {
                GADMobileAds.sharedInstance().start()
            }
    }
}
