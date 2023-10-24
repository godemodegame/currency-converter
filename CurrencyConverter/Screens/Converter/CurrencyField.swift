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

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .foregroundColor(.primary.opacity(0.1))
                .frame(height: 1)
            HStack {
                TextField("Enter amount", text: $enteredValue)
                    .padding()
                    .cornerRadius(10)
                    .keyboardType(.decimalPad)
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
            }
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
