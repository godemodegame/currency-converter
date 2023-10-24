//
//  ClearRowModifier.swift
//  CurrencyConverter
//
//  Created by Kirill Kirilenko on 29/04/2023.
//

import SwiftUI

struct ClearRowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(
                .init(
                    top: .zero,
                    leading: .zero,
                    bottom: .zero,
                    trailing: .zero
                )
            )
    }
}

extension View {
    func clearRow() -> some View {
        modifier(ClearRowModifier())
    }
}
