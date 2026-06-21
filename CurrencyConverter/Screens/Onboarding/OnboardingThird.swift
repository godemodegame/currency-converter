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
        VStack {
            Spacer()
            LottieView(lottieFile: "bitcoin", animationSpeed: 0.5)
                .frame(width: 200, height: 200)
            Text("Crypto support")
                .font(.title)
            Text("Not only fiat currencies are available, but also crypto")
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.bottom)
            Text("You can view rates of all major cryptocurrencies, including Bitcoin, Ethereum and more")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
            NavigationLink {
                OnboardingLast(close: $close)
            } label: {
                Text("Wow!")
                    .primaryButtonStyle()
            }
            .padding(.horizontal, 40)
            .padding(.bottom)
        }.navigationBarBackButtonHidden(true)
    }
}
