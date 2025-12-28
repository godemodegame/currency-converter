//
//  OnboardingThird.swift
//  CurrencyConverter
//
//  Created by Kirill Kirilenko on 03/05/2023.
//

import SwiftUI

struct OnboardingThird: View {
    @Binding var close: Bool

    var body: some View {
        ZStack {
            // Ocean gradient background
            Color.clear
                .oceanBackground()

            VStack(spacing: OceanSpacing.xl) {
                Spacer()

                LottieView(lottieFile: "bitcoin", animationSpeed: 0.5)
                    .frame(width: 200, height: 200)
                    .floatingAnimation()

                Text("Crypto support")
                    .font(.system(size: 32, weight: .bold))

                GlassCard {
                    VStack(spacing: OceanSpacing.sm) {
                        Text("Not only fiat currencis are available, but also crypto")
                            .font(.title3)
                            .multilineTextAlignment(.center)

                        Text("You can view rates of all major cryptocurrencies, including tokens from the TON blockchain")
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, OceanSpacing.lg)

                Spacer()

                NavigationLink {
                    OnboardingLast(close: $close)
                } label: {
                    Text("Wow!")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(LinearGradient.oceanButton)
                        .cornerRadius(OceanRadius.md)
                        .shadow(
                            color: Color.oceanBluePrimary.opacity(0.3),
                            radius: OceanShadow.medium.radius,
                            y: OceanShadow.medium.y
                        )
                }
                .padding(.horizontal, OceanSpacing.xxxl)
                .padding(.bottom, OceanSpacing.lg)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}
