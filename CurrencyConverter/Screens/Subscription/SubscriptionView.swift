//
//  SubscriptionView.swift
//  CurrencyConverter
//
//  Created by Kirill Kirilenko on 01/05/2023.
//

import SwiftUI
import Subscriptions

struct SubscriptionView: View {
    @EnvironmentObject var purchaseService: PurchaseService
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            Spacer()
            LottieView(lottieFile: "intro", animationSpeed: 1)
                .frame(width: 200, height: 200)
            Text("Subscription")
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, 20)
                .accessibilityIdentifier(AXID.Subscription.title)
            Text("You can use this app for free, but you will have a limited number of items in your favorites. To remove the limitation, subscribe")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom, 20)
            Text("1 Year = \(purchaseService.products.first?.displayPrice ?? "")")
            Spacer()
            LegalLinksRow { dismiss() }
            Button {
                Task {
                    guard let product = purchaseService.products.first else {
                        return
                    }
                    try? await purchaseService.purchase(product)
                    dismiss()
                }
            } label: {
                Text("Subscribe")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 40)
            .accessibilityIdentifier(AXID.Subscription.subscribeButton)
            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .padding(.bottom)
            .accessibilityIdentifier(AXID.Subscription.cancelButton)
        }
        .padding(.horizontal, 20)
    }
}

