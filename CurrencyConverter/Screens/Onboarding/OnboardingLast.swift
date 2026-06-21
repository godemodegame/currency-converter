//
//  OnboardingLast.swift
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
        VStack {
            Spacer()
            LottieView(lottieFile: "dolphin", animationSpeed: 0.5)
                .frame(width: 200, height: 200)
            Text("Well almost free!")
                .font(.title)
            Text("The number of exchange rates in the favorites is limited to five")
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding([.bottom, .horizontal])
            Text("If you want to support me and remove this restriction, you can subscribe")
                .multilineTextAlignment(.center)
                .padding([.bottom, .horizontal])
            Text("1 year - \(purchaseService.products.first?.displayPrice ?? "")")
            Spacer()
            LegalLinksRow { close = true }
            Button {
                Task {
                    guard let product = purchaseService.products.first else {
                        return
                    }
                    try? await purchaseService.purchase(product)
                    isFirstOpen = false
                    close.toggle()
                }
            } label: {
                Text("Support Developer")
                    .primaryButtonStyle()
            }
            .padding(.horizontal, 40)
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
                    .cornerRadius(10)
            }.opacity(showButton ? 1 : 0)
        }.task {
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

struct OnboardingLast_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingLast(close: .constant(false))
            .environmentObject(PurchaseService(productsId: [""]))
    }
}
