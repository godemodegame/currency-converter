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
            Text("You can use this app for free, but you will have a limited number of items in your favorites. To remove the limitation, subscribe")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom, 20)
            Text("1 Year = \(purchaseService.products.first?.displayPrice ?? "")")
            Spacer()
            HStack {
                Link(
                    "Terms of use",
                    destination: URL(
                        string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
                    )!
                )
                .foregroundColor(.gray)
                Link(
                    "Privacy Policy",
                    destination: URL(
                        string: "https://doc-hosting.flycricket.io/ocean-currency-converter-privacy-policy/e7d5acdd-6fd5-4d6b-bf93-46ebc57a05ec/privacy"
                    )!
                )
                .foregroundColor(.gray)
                Button {
                    Task {
                        do {
                            try await purchaseService.restore()
                            dismiss()
                        } catch {
                            print(error)
                        }
                    }
                } label: {
                    Text("Restore")
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                }
            }.padding(.vertical)
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
            }.padding(.horizontal, 40)
            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .font(.title3)
                    .fontWeight(.bold)
            }.padding(.bottom)
        }
        .padding(.horizontal, 20)
    }
}

