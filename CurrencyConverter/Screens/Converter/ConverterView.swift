//
//  ConverterView.swift
//  CurrencyConverter
//
//  Created by Kirill Kirilenko on 29/04/2023.
//

import GoogleMobileAds
import SwiftUI
import Subscriptions

struct ConverterView: View {
    @EnvironmentObject
    var viewModel: ConverterViewModel

    @EnvironmentObject
    var purchaseService: PurchaseService

    var body: some View {
        ZStack {
            // Ocean gradient background
            Color.clear
                .oceanBackground()

            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: OceanSpacing.sm) {
                        ForEach(viewModel.currencies) { currency in
                            GlassCard {
                                CurrencyRow(
                                    currency: currency,
                                    type: .base
                                )
                            }
                        }

                        // Hint text in glass card
                        GlassCard(cornerRadius: OceanRadius.lg) {
                            VStack(spacing: OceanSpacing.xs) {
                                Text("Enter the value in the field below")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Image(systemName: "arrow.down")
                                    .font(.system(size: 24, weight: .thin))
                                    .foregroundColor(.oceanTeal)
                                    .floatingAnimation()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, OceanSpacing.sm)
                        }
                    }
                    .padding(OceanSpacing.md)
                }

                if !purchaseService.hasUnlockedPro {
                    BannerView(viewWidth: UIScreen.main.bounds.width)
                        .frame(height: GADAdSizeBanner.size.height + 10)
                }

                CurrencyField(
                    enteredValue: $viewModel.enteredValue,
                    selectedCurrency: $viewModel.selectedCurrency,
                    currencies: viewModel.currencies
                )
            }
        }
        .task {
            await viewModel.loadData()
        }
    }
}

struct ConverterView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ConverterView()
                .environmentObject(ConverterViewModel())
                .environmentObject(PurchaseService(productsId: ["annual.ocean.plus"]))
                .navigationTitle("Rates")
                .onAppear {
                    GADMobileAds.sharedInstance().start()
                }
        }
    }
}
