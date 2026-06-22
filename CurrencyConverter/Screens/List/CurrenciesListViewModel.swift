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

    @Published private(set) var currencies: [Currency] = []
    @Published var error: Error?
    @Published var selectedSegment: CurrenciesListSegment = .favorite
    @Published var searchText = ""
    @Published var showPremium = false
    /// Published so bookmark state updates re-render the list without a manual
    /// `objectWillChange.send()`.
    @Published private(set) var favoriteCodes: Set<String> = []

    // MARK: Private properties

    @UserDefault(UserDefaultsKey.favoriteCurrencies, defaultValue: [])
    private var favoriteCurrencies: [String]

    /// Immutable source list; the displayed `currencies` is derived from it via
    /// `applyFilters()`, so narrowing by search/segment can always widen back.
    private var allCurrencies: [Currency] = []

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
        favoriteCodes = Set(favoriteCurrencies)
        // Filtering by segment/search is a pure local re-derivation off the
        // immutable source — no network refetch and no overlapping load tasks.
        // We filter with the *emitted* values: `@Published` fires its publisher
        // in `willSet`, so re-reading `self.selectedSegment` here would observe
        // the previous value and render results that lag one change behind.
        Publishers.CombineLatest($selectedSegment, $searchText)
            .dropFirst()
            .sink { [weak self] segment, searchText in
                self?.applyFilters(segment: segment, searchText: searchText)
            }
            .store(in: &bin)
    }

    // MARK: Public methods

    func loadData() async {
        let saved = await currencyService.getSavedCurrencies()
        if !saved.isEmpty, allCurrencies.isEmpty {
            allCurrencies = saved
            applyFilters()
        }
        do {
            let fresh = try await currencyService.getCurrencies()
            guard !Task.isCancelled else { return }
            allCurrencies = fresh
            applyFilters()
        } catch {
            self.error = error
        }
    }

    func isSaved(currency: Currency) -> Bool {
        favoriteCodes.contains(currency.code)
    }

    func pushed(currency: Currency) {
        if favoriteCodes.contains(currency.code) {
            favoriteCurrencies.removeAll { $0 == currency.code }
        } else if !purchaseService.hasUnlockedPro, favoriteCurrencies.count >= 5 {
            showPremium = true
            return
        } else {
            favoriteCurrencies.append(currency.code)
        }
        // Refresh the published set so bookmark icons re-render. We intentionally
        // do not re-filter here: as before, the visible rows stay put while
        // toggling and the favorites segment settles on the next load.
        favoriteCodes = Set(favoriteCurrencies)
    }

    // MARK: Private methods

    /// Re-derives the displayed list. `segment`/`searchText` default to the
    /// committed published values (used by the direct `loadData` call); the
    /// Combine subscription passes the freshly emitted values explicitly to
    /// avoid `willSet` staleness.
    private func applyFilters(
        segment: CurrenciesListSegment? = nil,
        searchText: String? = nil
    ) {
        let segment = segment ?? selectedSegment
        let searchText = searchText ?? self.searchText

        var result = allCurrencies
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(query)
                || $0.code.lowercased().contains(query)
            }
        }
        switch segment {
        case .favorite:
            result = result.filter { favoriteCodes.contains($0.code) }
        case .fiat:
            result = result.filter { $0.type == .fiat }
        case .crypto:
            result = result.filter { $0.type == .crypto }
        case .all:
            break
        }
        currencies = result.sorted {
            (favoriteCodes.contains($0.code) ? 0 : 1, $0.code) < (favoriteCodes.contains($1.code) ? 0 : 1, $1.code)
        }
    }
}
