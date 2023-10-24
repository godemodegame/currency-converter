//
//  CurrenciesListViewModel.swift
//  CurrencyConverter
//
//  Created by Kirill Kirilenko on 29/04/2023.
//

import Combine
import CurrencyCore
import SwiftUI
import Subscriptions

@MainActor
final class CurrenciesListViewModel: ObservableObject {
    // MARK: Public properties

    @Published var currencies: [Currency] = []
    @Published var error: Error?
    @Published var selectedSegment: CurrenciesListSegment = .favorite
    @Published var searchText = ""
    @Published var showPremium = false

    // MARK: Private properties

    @UserDefault("favoriteCurrencies", defaultValue: [])
    private var favoriteCurrencies: [String]

    private let purchaseService: PurchaseService
    private let currencyService: any CurrencyServiceProtocol
    private var bin: Set<AnyCancellable> = []

    // MARK: Lifecycle

    init(
        currencyService: any CurrencyServiceProtocol = CurrencyService(),
        purchaseService: PurchaseService
    ) {
        self.currencyService = currencyService
        self.purchaseService = purchaseService
        $selectedSegment
            .sink { [weak self] _ in
                Task {
                    await self?.loadData()
                }
            }.store(in: &bin)
        $searchText
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
                .sorted { favoriteCurrencies.contains($0.code) || $0.code < $1.code }
            applyFilters()
        }
        do {
            currencies = try await currencyService
                .getCurrencies()
                .sorted { favoriteCurrencies.contains($0.code) || $0.code < $1.code }
            applyFilters()
        } catch {
            self.error = error
        }
    }

    func isSaved(currency: Currency) -> Bool {
        favoriteCurrencies.contains(currency.code)
    }

    func pushed(currency: Currency) {
        if let currencyCode = favoriteCurrencies.first(where: { $0 == currency.code }) {
            favoriteCurrencies.removeAll { $0 == currencyCode }
        } else if !purchaseService.hasUnlockedPro && favoriteCurrencies.count >= 5 {
            showPremium = true
        } else {
            favoriteCurrencies.append(currency.code)
        }
        objectWillChange.send()
    }

    // MARK: Private methods

    private func applyFilters() {
        if !searchText.isEmpty {
            currencies = currencies.filter {
                $0.name.lowercased().contains(searchText.lowercased())
                || $0.code.lowercased().contains(searchText.lowercased())
            }
        }
        switch selectedSegment {
        case .favorite:
            currencies = currencies.filter { favoriteCurrencies.contains($0.code) }
        case .fiat:
            currencies = currencies.filter { $0.type == .fiat }
        case .crypto:
            currencies = currencies.filter { $0.type == .crypto }
        case .jettons:
            currencies = currencies.filter { $0.type == .jetton }
        case .all:
            return
        }
    }
}
