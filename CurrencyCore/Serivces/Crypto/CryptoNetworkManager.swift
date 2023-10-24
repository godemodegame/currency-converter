//
//  CryptoNetworkManager.swift
//  CurrencyCore
//
//  Created by Kirill Kirilenko on 03/05/2023.
//

public protocol CryptoNetworkManager: AnyObject {
    func getExchangeRates() async throws -> [DedustResponse]
}

public final class DedustNetworkManager: CryptoNetworkManager {
    private let baseUrl: String

    public init(baseUrl: String = "https://api.dedust.io") {
        self.baseUrl = baseUrl
    }

    public func getExchangeRates() async throws -> [DedustResponse] {
        guard let url = URL(string: "\(baseUrl)/v2/prices") else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode([DedustResponse].self, from: data)

        return response
    }
}
