//
//  HideScrollIndicatorsModifier.swift
//  CurrencyConverter
//
//  Created by Kirill Kirilenko on 30/04/2023.
//

import SwiftUI

@available(iOS 16.0, *)
struct HideScrollIndicatorsModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollIndicators(.hidden, axes: [.horizontal, .vertical])
    }
}

extension View {
    func hideScrollIndicators() -> some View {
        if #available(iOS 16.0, *) {
            return modifier(HideScrollIndicatorsModifier())
        }
        return self
    }
}
