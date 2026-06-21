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
    @Published private(set) var currencies: [Currency] = []
    @Published var selectedCurrency: String = ""

    // MARK: Private properties

    @UserDefault(UserDefaultsKey.favoriteCurrencies, defaultValue: [])
    private var favoriteCurrencies: [String]

    /// Immutable canonical (USD-based) snapshot of the favorite currencies.
    /// The displayed `currencies` is always derived from this; we never mutate
    /// the source in place.
    private var favorites: [Currency] = []

    private let currencyService: any CurrencyServiceProtocol
    private var bin: Set<AnyCancellable> = []

    // MARK: Lifecycle

    init(currencyService: any CurrencyServiceProtocol = CurrencyService()) {
        self.currencyService = currencyService
        // Changing the base currency or the amount is a pure local recompute —
        // no network refetch, so typing no longer hits the service per keystroke.
        Publishers.CombineLatest($selectedCurrency, $enteredValue)
            .dropFirst()
            .sink { [weak self] _ in self?.recompute() }
            .store(in: &bin)
    }

    // MARK: Public methods

    func loadData() async {
        let saved = await currencyService.getSavedCurrencies()
        if !saved.isEmpty, favorites.isEmpty {
            apply(source: saved)
        }
        do {
            let fresh = try await currencyService.getCurrencies()
            guard !Task.isCancelled else { return }
            apply(source: fresh)
        } catch {
            self.error = error
        }
    }

    // MARK: Private methods

    private func apply(source: [Currency]) {
        favorites = source.filter { favoriteCurrencies.contains($0.code) }
        if !favorites.contains(where: { $0.code == selectedCurrency }) {
            selectedCurrency = favorites.first?.code ?? "USD"
        }
        recompute()
    }

    private func recompute() {
        let amount = Double(enteredValue) ?? 1
        let sorted = favorites.sorted { $0.code == selectedCurrency || $0.code < $1.code }
        if let base = sorted.first(where: { $0.code == selectedCurrency }) {
            currencies = sorted.converted(against: base, amount: amount)
        } else {
            currencies = sorted
        }
    }
}
