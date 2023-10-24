//
//  JettonsNetworkManager.swift
//  CurrencyCore
//
//  Created by Kirill Kirilenko on 03/05/2023.
//

public protocol JettonsNetworkManager: AnyObject {
    func getExchangeRates() async throws -> RedoubtResponse
}

public final class RedoubtNetworkManager: JettonsNetworkManager {
    private let baseUrl: String

    public init(baseUrl: String = "https://api.redoubt.online") {
        self.baseUrl = baseUrl
    }

    public func getExchangeRates() async throws -> RedoubtResponse {
        guard let url = URL(string: "\(baseUrl)/v1/jettons/top") else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(RedoubtResponse.self, from: data)

        return response
    }
}
