//
//  OnboardingSecond.swift
//  CurrencyConverter
//
//  Created by Kirill Kirilenko on 30/04/2023.
//

import SwiftUI

struct OnboardingSecond: View {
    @Binding var close: Bool

    var body: some View {
        ZStack {
            // Ocean gradient background
            Color.clear
                .oceanBackground()

            VStack(spacing: OceanSpacing.xl) {
                Spacer()

                LottieView(lottieFile: "whale", animationSpeed: 0.5)
                    .frame(width: 200, height: 200)
                    .floatingAnimation()

                Text("Currency converter!")
                    .font(.system(size: 32, weight: .bold))

                GlassCard {
                    VStack(spacing: OceanSpacing.sm) {
                        Text("It's a pretty simple but clever app!")
                            .font(.title3)
                            .multilineTextAlignment(.center)

                        Text("It is sure to come in handy in life and travel\nYou can add multiple currencies\nTo count in multiple currencies at once!")
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, OceanSpacing.lg)

                Spacer()

                NavigationLink {
                    OnboardingThird(close: $close)
                } label: {
                    Text("Show me more")
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

struct OnboardingSecond_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingSecond(close: .constant(false))
    }
}
