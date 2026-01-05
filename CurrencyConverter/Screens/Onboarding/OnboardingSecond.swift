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
        VStack {
            Spacer()
            LottieView(lottieFile: "whale", animationSpeed: 0.5)
                .frame(width: 200, height: 200)
            Text("Currency converter!")
                .font(.title)
            Text("It's a pretty simple but clever app!")
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.bottom)
            Text("It is sure to come in handy in life and travel\nYou can add multiple currencies\nTo count in multiple currencies at once!")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
            NavigationLink {
                OnboardingThird(close: $close)
            } label: {
                Text("Show me more")
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 40)
            .padding(.bottom)
        }.navigationBarBackButtonHidden(true)
    }
}

struct OnboardingSecond_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingSecond(close: .constant(false))
    }
}
