//
//  OnboardingThree.swift
//  CurrencyConverter
//
//  Created by Kirill Kirilenko on 30/04/2023.
//

import AdSupport
import AppTrackingTransparency
import SwiftUI
import Subscriptions

struct OnboardingLast: View {
    @AppStorage("isFirstOpen") var isFirstOpen = true
    @Binding var close: Bool
    @EnvironmentObject var purchaseService: PurchaseService

    @State var showButton = false

    var body: some View {
        ZStack {
            // Ocean gradient background
            Color.clear
                .oceanBackground()

            ScrollView {
                VStack(spacing: OceanSpacing.xl) {
                    Spacer()
                        .frame(height: OceanSpacing.xl)

                    LottieView(lottieFile: "dolphin", animationSpeed: 0.5)
                        .frame(width: 200, height: 200)
                        .floatingAnimation()

                    Text("Well almost free!")
                        .font(.system(size: 32, weight: .bold))

                    GlassCard {
                        VStack(spacing: OceanSpacing.sm) {
                            Text("The number of exchange rates in the favorites is limited to five")
                                .font(.title3)
                                .multilineTextAlignment(.center)

                            Text("If you want to support me and remove this restriction, you can subscribe")
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, OceanSpacing.lg)

                    GlassCard {
                        Text("1 year - \(purchaseService.products.first?.displayPrice ?? "")")
                            .font(.headline)
                            .foregroundColor(.oceanBluePrimary)
                    }
                    .padding(.horizontal, OceanSpacing.xl)

                    Spacer()
                        .frame(height: OceanSpacing.md)

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
                                    close = true
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

                    OceanButton(title: "Support Developer", style: .primary) {
                        Task {
                            guard let product = purchaseService.products.first else { return }
                            try? await purchaseService.purchase(product)
                            isFirstOpen = false
                            close.toggle()
                        }
                    }
                    .padding(.horizontal, OceanSpacing.xxxl)

                    Button {
                        Task {
                            await ATTrackingManager.requestTrackingAuthorization()
                            isFirstOpen = false
                            close.toggle()
                        }
                    } label: {
                        Text("May be later")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .opacity(showButton ? 1 : 0)
                    .padding(.bottom, OceanSpacing.lg)
                }
            }
        }
        .task {
            do {
                try await Task.sleep(nanoseconds: 3_000_000_000)
                withAnimation {
                    showButton = true
                }
            } catch {
                showButton = true
            }
        }.navigationBarBackButtonHidden(true)
    }
}

struct OnboardingThree_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingLast(close: .constant(false))
            .environmentObject(PurchaseService(productsId: [""]))
    }
}
