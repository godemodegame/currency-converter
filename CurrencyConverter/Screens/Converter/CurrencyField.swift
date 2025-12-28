//
//  CurrencyField.swift
//  CurrencyConverter
//
//  Created by Kirill Kirilenko on 29/04/2023.
//

import Combine
import CurrencyCore
import SwiftUI

struct CurrencyField: View {
    @Binding var enteredValue: String
    @Binding var selectedCurrency: String

    let currencies: [Currency]
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.2))

            HStack(spacing: OceanSpacing.md) {
                TextField("Enter amount", text: $enteredValue)
                    .font(.system(size: 20, weight: .semibold))
                    .keyboardType(.decimalPad)
                    .foregroundColor(.primary)
                    .padding(OceanSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: OceanRadius.sm)
                            .fill(Color.white.opacity(0.1))
                            .blur(radius: OceanBlur.ultraLight)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: OceanRadius.sm)
                            .strokeBorder(
                                isFocused ? Color.oceanTeal.opacity(0.6) : Color.clear,
                                lineWidth: 2
                            )
                    )
                    .focused($isFocused)
                    .onReceive(Just(enteredValue)) { newValue in
                        let filtered = newValue.filter {
                            "0123456789.".contains($0)
                        }
                        if filtered != newValue {
                            enteredValue = filtered
                        }
                        if Double(newValue) == 0 {
                            enteredValue = ""
                        }
                    }

                Picker(selectedCurrency, selection: $selectedCurrency) {
                    ForEach(currencies) { currency in
                        Text(currency.code)
                            .tag(currency.code)
                    }
                }
                .tint(.oceanBluePrimary)
            }
            .padding(OceanSpacing.md)
            .background(
                Color.white.opacity(0.15)
                    .blur(radius: OceanBlur.medium)
            )
        }
    }
}

struct CurrencyField_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ConverterView()
                .environmentObject(ConverterViewModel(currencyService: CurrencyService()))
                .navigationTitle("Rates")
        }
    }
}
