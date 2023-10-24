//
//  ConverterViewModel.swift
//  CurrencyConverter
//
//  Created by Kirill Kirilenko on 29/04/2023.
//

import Combine
import CurrencyCore
import SwiftUI

@MainActor
final class ConverterViewModel: ObservableObject {
    // MARK: Public properties

    @Published var enteredValue: String = ""
    @Published var error: Error?
    @Published var currencies: [Currency] = []
    @Published var selectedCurrency: String = ""

    // MARK: Private properties

    @UserDefault("favoriteCurrencies", defaultValue: [])
    private var favoriteCurrencies: [String]

    private let currencyService: any CurrencyServiceProtocol
    private var bin: Set<AnyCancellable> = []

    // MARK: Lifecycle

    init(currencyService: any CurrencyServiceProtocol = CurrencyService()) {
        self.currencyService = currencyService
        $selectedCurrency
            .sink { [weak self] _ in
                Task {
                    await self?.loadData()
                }
            }.store(in: &bin)
        $enteredValue
            .sink { [weak self] _ in
                Task {
                    await self?.loadData()
                }
            }.store(in: &bin)
    }

    // MARK: Public methods

    func loadData() async {
        let savedCurrencies = await currencyService.getSavedCurrencies()
        if !savedCurrencies.isEmpty, currencies.isEmpty {
            currencies = savedCurrencies
                .filter { favoriteCurrencies.contains($0.code) }
                .sorted { $0.code == selectedCurrency || $0.code < $1.code }
            selectedCurrency = currencies.first?.code ?? "USD"
            updateCurrencies()
        }
        do {
            currencies = try await currencyService
                .getCurrencies()
                .filter { favoriteCurrencies.contains($0.code) }
                .sorted { $0.code == selectedCurrency || $0.code < $1.code }
            updateCurrencies()
        } catch {
            self.error = error
        }
    }

    // MARK: Private methods

    private func updateCurrencies() {
        let amount = Double(enteredValue) ?? 1
        if let selectedValue = currencies.first(where: { $0.code == selectedCurrency}) {
            currencies = currencies.map {
                Currency(
                    name: $0.name,
                    imageSource: $0.imageSource,
                    code: $0.code,
                    rate: $0.rate / selectedValue.rate * amount,
                    type: $0.type
                )
            }
        }
    }
}
