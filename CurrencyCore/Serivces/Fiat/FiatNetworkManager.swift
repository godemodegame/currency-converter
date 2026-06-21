//
//  FiatNetworkManager.swift
//  CurrencyCore
//
//  Created by Kirill Kirilenko on 29/04/2023.
//

import Foundation

public protocol FiatNetworkManager: AnyObject {
    func getExchangeRates(currencyCode: String) async throws -> ExchangeRatesResponse
}

public final class FiatNetwork: FiatNetworkManager {
    private let baseUrl: String
    private let client: NetworkClient

    public init(
        baseUrl: String = "https://api.frankfurter.app",
        client: NetworkClient = URLSessionNetworkClient()
    ) {
        self.baseUrl = baseUrl
        self.client = client
    }

    public func getExchangeRates(currencyCode: String) async throws -> ExchangeRatesResponse {
        try await client.get(
            baseURL: baseUrl,
            path: "/latest",
            queryItems: [URLQueryItem(name: "from", value: currencyCode)],
            as: ExchangeRatesResponse.self
        )
    }
}
