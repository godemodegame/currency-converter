//
//  SharedUI.swift
//  CurrencyConverter
//
//  Shared UI building blocks used across onboarding and the paywall.
//

import Foundation
import SwiftUI
import Subscriptions

extension View {
    /// The app's primary blue call-to-action styling, applied to a button's label.
    func primaryButtonStyle() -> some View {
        font(.title3)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(10)
    }
}

/// Centralized external links shown in the paywall / onboarding.
enum AppLinks {
    static let termsOfUse = URL(
        string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
    )!
    static let privacyPolicy = URL(
        string: "https://doc-hosting.flycricket.io/ocean-currency-converter-privacy-policy/e7d5acdd-6fd5-4d6b-bf93-46ebc57a05ec/privacy"
    )!
}

/// Terms / Privacy links plus a Restore-purchases button, shared by the paywall
/// and the onboarding's final screen. `onRestored` runs after a successful restore.
struct LegalLinksRow: View {
    @EnvironmentObject private var purchaseService: PurchaseService
    var onRestored: () -> Void

    var body: some View {
        HStack {
            Link("Terms of use", destination: AppLinks.termsOfUse)
                .foregroundColor(.gray)
            Link("Privacy Policy", destination: AppLinks.privacyPolicy)
                .foregroundColor(.gray)
            Button {
                Task {
                    do {
                        try await purchaseService.restore()
                        onRestored()
                    } catch {
                        print(error)
                    }
                }
            } label: {
                Text("Restore")
                    .foregroundColor(.gray)
                    .font(.system(size: 16))
            }
        }
        .padding(.vertical)
    }
}
