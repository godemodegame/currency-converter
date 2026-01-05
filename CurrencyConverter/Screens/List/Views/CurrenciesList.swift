//
//  CurrenciesList.swift
//  CurrencyConverter
//
//  Created by Kirill Kirilenko on 29/04/2023.
//

import SwiftUI
import Subscriptions

struct CurrenciesList: View {
    @EnvironmentObject
    var viewModel: CurrenciesListViewModel

    var body: some View {
        List {
            Section {
                Picker("Picker", selection: $viewModel.selectedSegment) {
                    ForEach(CurrenciesListSegment.allCases, id: \.self) {
                        Text($0.rawValue.capitalized)
                    }
                }
                .pickerStyle(.segmented)
            }
            .clearRow()

            ForEach(viewModel.currencies) { currency in
                Button { [weak viewModel] in
                    viewModel?.pushed(currency: currency)
                } label: {
                    CurrencyRow(
                        currency: currency,
                        type: .selection(
                            viewModel.isSaved(
                                currency: currency
                            )
                        )
                    ).foregroundColor(.primary)
                }
            }
        }
        .sheet(isPresented: $viewModel.showPremium) {
            SubscriptionView()
        }
        .hideScrollIndicators()
        .searchable(text: $viewModel.searchText)
        .listStyle(.insetGrouped)
        .task {
            await viewModel.loadData()
        }.navigationTitle("Currencies List")
    }
}

struct CurrenciesList_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CurrenciesList()
                .environmentObject(CurrenciesListViewModel(purchaseService: PurchaseService(productsId: ["annual.ocean.plus"])))
        }
    }
}
