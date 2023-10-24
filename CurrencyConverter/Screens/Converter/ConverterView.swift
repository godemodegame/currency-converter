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
        VStack(spacing: 0) {
            List() {
                ForEach(viewModel.currencies) { currency in
                    CurrencyRow(
                        currency: currency,
                        type: .base
                    )
                }
                HStack {
                    Spacer()
                    Text("Enter the value in the field below")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Spacer()
                }.clearRow()
                HStack {
                    Spacer()
                    Image(systemName: "arrow.down")
                        .font(.system(size: 30, weight: .thin))
                        .foregroundColor(.gray)
                    Spacer()
                }.clearRow()
                
            }
            .listStyle(.insetGrouped)
            .hideScrollIndicators()

            if !purchaseService.hasUnlockedPro {
                BannerView(viewWidth: UIScreen.main.bounds.width)
                    .frame(height: GADAdSizeBanner.size.height + 10)
            }

            CurrencyField(
                enteredValue: $viewModel.enteredValue,
                selectedCurrency: $viewModel.selectedCurrency,
                currencies: viewModel.currencies
            )
        }.task {
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
