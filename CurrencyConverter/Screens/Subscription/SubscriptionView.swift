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

    private var subscriptionPriceText: String {
        guard let price = purchaseService.products.first?.displayPrice, !price.isEmpty else {
            return "Loading price..."
        }
        return "1 year - \(price)"
    }
    
    var body: some View {
        VStack {
            Spacer()
            SubscriptionHeroView()
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
            Text(subscriptionPriceText)
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
        .task {
            await purchaseService.loadProducts()
        }
    }
}

private struct SubscriptionHeroView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.16),
                            Color.green.opacity(0.14),
                            Color.orange.opacity(0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 168, height: 168)

            Circle()
                .stroke(Color.blue.opacity(0.18), lineWidth: 1)
                .frame(width: 168, height: 168)

            CurrencyBadge(systemName: "dollarsign", color: .green)
                .offset(x: -48, y: -44)

            CurrencyBadge(systemName: "eurosign", color: .blue)
                .offset(x: 48, y: -36)

            CurrencyBadge(systemName: "yensign", color: .orange)
                .offset(x: -40, y: 48)

            Circle()
                .fill(Color(.systemBackground))
                .frame(width: 86, height: 86)
                .shadow(color: Color.black.opacity(0.10), radius: 18, x: 0, y: 10)
                .overlay(
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundColor(.blue)
                )
        }
        .accessibilityHidden(true)
    }
}

private struct CurrencyBadge: View {
    let systemName: String
    let color: Color

    var body: some View {
        Circle()
            .fill(Color(.systemBackground))
            .frame(width: 54, height: 54)
            .shadow(color: color.opacity(0.22), radius: 12, x: 0, y: 7)
            .overlay(
                Image(systemName: systemName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(color)
            )
    }
}
