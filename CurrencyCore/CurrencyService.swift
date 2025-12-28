//
//  CurrencyService.swift
//  CurrencyCore
//
//  Created by Kirill Kirilenko on 29/04/2023.
//

public protocol CurrencyServiceProtocol: AnyObject, ObservableObject {
    func getCurrencies(currencyCode: String) async throws -> [Currency]
    func getSavedCurrencies() async -> [Currency]
}

public extension CurrencyServiceProtocol {
    func getCurrencies() async throws -> [Currency] {
        try await getCurrencies(currencyCode: "USD")
    }
}

public actor CurrencyService: CurrencyServiceProtocol {
    // MARK: Private properties

    private let fiatNetworkManager: FiatNetworkManager
    private let fiatWorker: FiatCurrencyWorker
    private let cryptoNetworkManager: CryptoNetworkManager
    private let cryptoWorker: CryptoCurrencyWorker

    private var currencies: [Currency] = []

    @UserDefault("savedCurrencies", defaultValue: [], userDefaults: .standard)
    private var oldSavedCurrencies: [Currency]

    @UserDefault("savedCurrencies", defaultValue: [])
    private var savedCurrencies: [Currency]

    @UserDefault("favoriteCurrencies", defaultValue: [], userDefaults: .standard)
    private var oldFavoriteCurrencies: [String]

    @UserDefault("favoriteCurrencies", defaultValue: [])
    private var favoriteCurrencies: [String]

    // MARK: Lifecycle
    public init(
        fiatNetworkManager: FiatNetworkManager = FiatNetwork(),
        fiatWorker: FiatCurrencyWorker = FiatWorker(),
        cryptoNetworkManager: CryptoNetworkManager = DedustNetworkManager(),
        cryptoWorker: CryptoCurrencyWorker = CryptoWorker()
    ) {
        self.fiatNetworkManager = fiatNetworkManager
        self.fiatWorker = fiatWorker
        self.cryptoNetworkManager = cryptoNetworkManager
        self.cryptoWorker = cryptoWorker
    }

    // MARK: - CurrencyServiceProtocol

    public func getSavedCurrencies() async -> [Currency] {
        if !oldSavedCurrencies.isEmpty {
            savedCurrencies = oldSavedCurrencies
            oldSavedCurrencies = []
        }
        if !oldFavoriteCurrencies.isEmpty {
            favoriteCurrencies = oldFavoriteCurrencies
            oldFavoriteCurrencies = []
        }
        return savedCurrencies
    }

    public func getCurrencies(currencyCode: String) async throws -> [Currency] {
        if !currencies.isEmpty {
            return currencies
        }

        let fiat = try fiatWorker.prepareCurrencies(
            try await fiatNetworkManager.getExchangeRates(
                currencyCode: currencyCode
            )
        )
        let crypto = try cryptoWorker.prepareCurrencies(
            try await cryptoNetworkManager.getExchangeRates()
        )

        currencies = fiat
        currencies.append(contentsOf: crypto)
        currencies.sort { $0.code < $1.code }
        savedCurrencies = currencies
        return currencies
    }
}
