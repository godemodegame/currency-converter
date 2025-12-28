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
        ZStack {
            // Ocean gradient background
            Color.clear
                .oceanBackground()

            VStack(spacing: OceanSpacing.md) {
                // Glass segmented picker
                GlassCard {
                    Picker("Picker", selection: $viewModel.selectedSegment) {
                        ForEach(CurrenciesListSegment.allCases, id: \.self) {
                            Text($0.rawValue.capitalized)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal, OceanSpacing.md)
                .padding(.top, OceanSpacing.xs)

                ScrollView {
                    LazyVStack(spacing: OceanSpacing.xs) {
                        ForEach(viewModel.currencies) { currency in
                            Button { [weak viewModel] in
                                viewModel?.pushed(currency: currency)
                            } label: {
                                CurrencyRow(
                                    currency: currency,
                                    type: .selection(
                                        viewModel.isSaved(currency: currency)
                                    )
                                )
                                .foregroundColor(.primary)
                                .padding(.horizontal, OceanSpacing.md)
                                .padding(.vertical, OceanSpacing.xs)
                                .background(
                                    RoundedRectangle(cornerRadius: OceanRadius.sm)
                                        .fill(Color.white.opacity(0.1))
                                )
                            }
                        }
                    }
                    .padding(.horizontal, OceanSpacing.md)
                }
                .searchable(text: $viewModel.searchText)
            }
        }
        .sheet(isPresented: $viewModel.showPremium) {
            SubscriptionView()
        }
        .task {
            await viewModel.loadData()
        }
        .navigationTitle("Currencies List")
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
