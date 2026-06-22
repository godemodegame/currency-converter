//
//  ViewModelTests.swift
//  CurrencyConverterTests
//
//  Black-box coverage of the converter + list ViewModels through their public
//  API (`apply`/`recompute`/`applyFilters` are private). Inputs are set *before*
//  `loadData()` so the reliable direct recompute/applyFilters picks them up —
//  avoiding the `@Published`-in-`willSet` staleness of the Combine path.
//
//  Both ViewModels persist favorites to the shared (non-injectable) app-group
//  suite, so the two suites must not run concurrently with each other. They're
//  nested under one `.serialized` parent — serialization is recursive, so it
//  covers both child suites and their tests.
//

import Testing
import CurrencyCore
import Subscriptions
@testable import CurrencyConverter

@Suite(.serialized) struct ViewModelTests {

    // MARK: - Converter

    @MainActor struct ConverterTests {
        init() { FavoritesStore.seed(nil) }

        @Test func loadDataFiltersToFavorites() async {
            FavoritesStore.seed(["USD", "EUR", "BTC"])
            let vm = ConverterViewModel(currencyService: MockCurrencyService(fresh: sampleCurrencies()))

            await vm.loadData()

            // GBP is in the source but not a favorite → excluded.
            #expect(Set(vm.currencies.map(\.code)) == ["USD", "EUR", "BTC"])
        }

        @Test func convertsAgainstSelectedBase() async {
            FavoritesStore.seed(["USD", "EUR", "BTC"])
            let vm = ConverterViewModel(currencyService: MockCurrencyService(fresh: sampleCurrencies()))
            vm.selectedCurrency = "EUR" // a favorite → preserved by apply()

            await vm.loadData()

            // The base currency always converts to the entered amount (1 by default).
            let eur = vm.currencies.first { $0.code == "EUR" }
            #expect(isApprox(eur?.rate ?? 0, 1))
            // USD per 1 EUR == USD.rate / EUR.rate == 1 / 0.92
            let usd = vm.currencies.first { $0.code == "USD" }
            #expect(isApprox(usd?.rate ?? 0, 1 / 0.92))
            // The selected base sorts first; the rest follow alphabetically.
            #expect(vm.currencies.first?.code == "EUR")
        }

        @Test func amountScalesConvertedRates() async {
            FavoritesStore.seed(["USD", "EUR"])
            let vm = ConverterViewModel(currencyService: MockCurrencyService(fresh: sampleCurrencies()))
            vm.selectedCurrency = "USD"
            vm.enteredValue = "2"

            await vm.loadData()

            let usd = vm.currencies.first { $0.code == "USD" }
            #expect(isApprox(usd?.rate ?? 0, 2)) // base * amount
            let eur = vm.currencies.first { $0.code == "EUR" }
            #expect(isApprox(eur?.rate ?? 0, 0.92 * 2))
        }

        @Test func invalidAmountFallsBackToOne() async {
            FavoritesStore.seed(["USD", "EUR"])
            let vm = ConverterViewModel(currencyService: MockCurrencyService(fresh: sampleCurrencies()))
            vm.selectedCurrency = "USD"
            vm.enteredValue = "not a number"

            await vm.loadData()

            let eur = vm.currencies.first { $0.code == "EUR" }
            #expect(isApprox(eur?.rate ?? 0, 0.92)) // amount defaults to 1
        }

        @Test func selectedCurrencyResetsWhenNotAFavorite() async {
            FavoritesStore.seed(["USD", "EUR"])
            let vm = ConverterViewModel(currencyService: MockCurrencyService(fresh: sampleCurrencies()))
            vm.selectedCurrency = "JPY" // not in favorites

            await vm.loadData()

            // Falls back to the first favorite.
            #expect(vm.selectedCurrency == "USD")
        }

        @Test func serviceErrorIsSurfaced() async {
            FavoritesStore.seed(["USD"])
            let vm = ConverterViewModel(currencyService: MockCurrencyService(error: CurrencyError.invalidResponse))

            await vm.loadData()

            #expect(vm.error != nil)
            #expect(vm.currencies.isEmpty)
        }
    }

    // MARK: - List

    @MainActor struct ListTests {
        init() { FavoritesStore.seed(nil) }

        private func makeViewModel(fresh: [Currency] = sampleCurrencies()) -> CurrenciesListViewModel {
            CurrenciesListViewModel(
                currencyService: MockCurrencyService(fresh: fresh),
                purchaseService: PurchaseService(productsId: [])
            )
        }

        @Test func seedsFavoriteCodesFromStore() {
            FavoritesStore.seed(["USD", "EUR"])
            let vm = makeViewModel()
            #expect(vm.favoriteCodes == ["USD", "EUR"])
        }

        @Test func loadDataPopulatesAllCurrencies() async {
            FavoritesStore.seed([])
            let vm = makeViewModel()
            vm.selectedSegment = .all

            await vm.loadData()

            #expect(vm.currencies.count == sampleCurrencies().count)
        }

        @Test func favoritesSortFirstThenAlphabetical() async {
            FavoritesStore.seed(["GBP"])
            let vm = makeViewModel()
            vm.selectedSegment = .all

            await vm.loadData()

            // GBP (favorite) leads; the rest follow alphabetically.
            #expect(vm.currencies.map(\.code) == ["GBP", "BTC", "EUR", "USD"])
        }

        @Test func favoriteSegmentShowsOnlyFavorites() async {
            FavoritesStore.seed(["USD", "EUR"])
            let vm = makeViewModel() // default segment is .favorite

            await vm.loadData()

            #expect(Set(vm.currencies.map(\.code)) == ["USD", "EUR"])
        }

        @Test func fiatSegmentFiltersByType() async {
            FavoritesStore.seed([])
            let vm = makeViewModel()
            vm.selectedSegment = .fiat

            await vm.loadData()

            #expect(Set(vm.currencies.map(\.code)) == ["USD", "EUR", "GBP"])
        }

        @Test func cryptoSegmentFiltersByType() async {
            FavoritesStore.seed([])
            let vm = makeViewModel()
            vm.selectedSegment = .crypto

            await vm.loadData()

            #expect(vm.currencies.map(\.code) == ["BTC"])
        }

        @Test func searchMatchesNameCaseInsensitively() async {
            FavoritesStore.seed([])
            let vm = makeViewModel()
            vm.selectedSegment = .all
            vm.searchText = "BIT" // matches "Bitcoin"

            await vm.loadData()

            #expect(vm.currencies.map(\.code) == ["BTC"])
        }

        @Test func searchMatchesCode() async {
            FavoritesStore.seed([])
            let vm = makeViewModel()
            vm.selectedSegment = .all
            vm.searchText = "eur"

            await vm.loadData()

            #expect(vm.currencies.map(\.code) == ["EUR"])
        }

        @Test func searchAndSegmentCombine() async {
            FavoritesStore.seed([])
            let vm = makeViewModel()
            vm.selectedSegment = .fiat
            vm.searchText = "euro" // BTC excluded by segment, USD/GBP by search

            await vm.loadData()

            #expect(vm.currencies.map(\.code) == ["EUR"])
        }

        @Test func pushedAddsAndRemovesFavorite() {
            FavoritesStore.seed(["USD", "EUR"])
            let vm = makeViewModel()

            vm.pushed(currency: makeCurrency("GBP"))
            #expect(vm.favoriteCodes.contains("GBP"))
            #expect(FavoritesStore.current.contains("GBP"))

            vm.pushed(currency: makeCurrency("USD"))
            #expect(!vm.favoriteCodes.contains("USD"))
            #expect(!FavoritesStore.current.contains("USD"))
        }

        @Test func freeTierFavoriteLimitTriggersPremium() {
            FavoritesStore.seed(["USD", "EUR", "GBP", "JPY", "CHF"]) // already 5
            let vm = makeViewModel()

            vm.pushed(currency: makeCurrency("BTC", type: .crypto))

            #expect(vm.showPremium)
            #expect(!vm.favoriteCodes.contains("BTC"))
            #expect(vm.favoriteCodes.count == 5)
        }

        @Test func isSavedReflectsMembership() {
            FavoritesStore.seed(["USD"])
            let vm = makeViewModel()

            #expect(vm.isSaved(currency: makeCurrency("USD")))
            #expect(!vm.isSaved(currency: makeCurrency("BTC", type: .crypto)))
        }
    }
}
