//
//  OnboardingFirst.swift
//  CurrencyConverter
//
//  Created by Kirill Kirilenko on 30/04/2023.
//

import SwiftUI

struct OnboardingFirst: View {
    @Binding var close: Bool

    @State var showIcon = false
    @State var showTexts = false
    @State var showButton = false

    var body: some View {
        ZStack {
            // Ocean gradient background
            Color.clear
                .oceanBackground()

            VStack(spacing: OceanSpacing.xl) {
                Spacer()

                Image("icon")
                    .resizable()
                    .frame(width: 200, height: 200)
                    .cornerRadius(40)
                    .opacity(showIcon ? 1 : 0)
                    .scaleEffect(showIcon ? 1 : 0.8)

                Text("Thank you")
                    .font(.system(size: 32, weight: .bold))
                    .opacity(showTexts ? 1 : 0)

                Text("for downloading my app")
                    .font(.title3)
                    .opacity(showTexts ? 1 : 0)

                Spacer()

                NavigationLink {
                    OnboardingSecond(close: $close)
                } label: {
                    Text("What does the app do?")
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
                .opacity(showButton ? 1 : 0)
            }
        }
        .task {
            do {
                try await Task.sleep(nanoseconds: 500_000_000)
                withAnimation {
                    showIcon = true
                }
                try await Task.sleep(nanoseconds: 1_000_000_000)
                withAnimation {
                    showTexts = true
                }
                try await Task.sleep(nanoseconds: 1_000_000_000)
                withAnimation {
                    showButton = true
                }
            } catch {
                showIcon = true
                showTexts = true
                showButton = true
            }
        }
    }
}

struct OnboardingFirst_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingFirst(close: .constant(false))
    }
}
