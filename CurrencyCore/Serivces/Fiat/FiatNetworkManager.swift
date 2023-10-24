//
//  FiatNetworkManager.swift
//  CurrencyCore
//
//  Created by Kirill Kirilenko on 29/04/2023.
//

public protocol FiatNetworkManager: AnyObject {
    func getExchangeRates(currencyCode: String) async throws -> ExchangeRatesResponse
}

extension FiatNetworkManager {
    func getExchangeRates() async throws -> ExchangeRatesResponse {
        try await getExchangeRates(currencyCode: "USD")
    }
}

public final class FiatNetwork: FiatNetworkManager {
    private let baseUrl: String

    public init(baseUrl: String = "https://open.er-api.com") {
        self.baseUrl = baseUrl
    }

    public func getExchangeRates(currencyCode: String) async throws -> ExchangeRatesResponse {
        guard let url = URL(string: "\(baseUrl)/v6/latest/\(currencyCode)") else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(ExchangeRatesResponse.self, from: data)

        return response
    }
}
