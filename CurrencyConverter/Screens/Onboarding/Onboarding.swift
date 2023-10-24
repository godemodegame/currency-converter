//
//  Onboarding.swift
//  CurrencyConverter
//
//  Created by Kirill Kirilenko on 30/04/2023.
//

import Combine
import SwiftUI
import Subscriptions

struct Onboarding: View {
    @Environment(\.dismiss) var dismiss
    @State var close: Bool = false
    @EnvironmentObject var purchaseService: PurchaseService

    var body: some View {
        NavigationView {
            OnboardingFirst(close: $close)
        }
        .interactiveDismissDisabled()
        .onReceive(Just(close)) { _ in
            if close == true {
                dismiss()
            }
        }
    }
}

struct Onboarding_Previews: PreviewProvider {
    static var previews: some View {
        Onboarding()
            .environmentObject(PurchaseService(productsId: ["annual.ocean.plus"]))
    }
}
