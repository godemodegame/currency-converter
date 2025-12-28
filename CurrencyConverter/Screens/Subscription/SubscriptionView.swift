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
        ZStack {
            // Ocean gradient background
            Color.clear
                .oceanBackground()

            ScrollView {
                VStack(spacing: OceanSpacing.xl) {
                    Spacer()
                        .frame(height: OceanSpacing.xl)

                    // Lottie animation
                    LottieView(lottieFile: "intro", animationSpeed: 1)
                        .frame(width: 200, height: 200)

                    // Title
                    Text("Subscription")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)

                    // Description in glass card
                    GlassCard {
                        Text("You can use this app for free, but you will have a limited number of items in your favorites. To remove the limitation, subscribe")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, OceanSpacing.lg)

                    // Pricing card
                    GlassCard {
                        VStack(spacing: OceanSpacing.sm) {
                            Text("Annual Subscription")
                                .font(.headline)
                            Text(purchaseService.products.first?.displayPrice ?? "")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.oceanBluePrimary)
                        }
                        .padding(OceanSpacing.md)
                    }
                    .padding(.horizontal, OceanSpacing.xl)

                    Spacer()
                        .frame(height: OceanSpacing.xl)

                    // Links
                    HStack(spacing: OceanSpacing.lg) {
                        Link("Terms", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                            .font(.caption)
                            .foregroundColor(.oceanTeal)

                        Link("Privacy", destination: URL(string: "https://doc-hosting.flycricket.io/ocean-currency-converter-privacy-policy/e7d5acdd-6fd5-4d6b-bf93-46ebc57a05ec/privacy")!)
                            .font(.caption)
                            .foregroundColor(.oceanTeal)

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
                                .font(.caption)
                                .foregroundColor(.oceanTeal)
                        }
                    }
                    .padding(.vertical, OceanSpacing.md)

                    // Subscribe button
                    OceanButton(title: "Subscribe", style: .primary) {
                        Task {
                            guard let product = purchaseService.products.first else { return }
                            try? await purchaseService.purchase(product)
                            dismiss()
                        }
                    }
                    .padding(.horizontal, OceanSpacing.xxxl)

                    // Cancel button
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, OceanSpacing.lg)
                }
            }
        }
    }
}

