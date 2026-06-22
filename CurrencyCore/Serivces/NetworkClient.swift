//
//  NetworkClient.swift
//  CurrencyCore
//
//  Shared networking used by the fiat and crypto network managers.
//

import Foundation

public protocol NetworkClient: Sendable {
    func get<T: Decodable>(_ url: URL, as type: T.Type) async throws -> T
}

public extension NetworkClient {
    /// Builds a URL from a base, path, and query items (values are percent-encoded
    /// via `URLComponents`), throwing `.invalidURL` if it can't be formed, then
    /// GETs and decodes the response. Lets callers skip the manual
    /// `URL(string:)` + `guard … else { throw .invalidURL }` boilerplate.
    func get<T: Decodable>(
        baseURL: String,
        path: String,
        queryItems: [URLQueryItem] = [],
        as type: T.Type
    ) async throws -> T {
        guard var components = URLComponents(string: baseURL) else {
            throw CurrencyError.invalidURL
        }
        components.path = path
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw CurrencyError.invalidURL
        }
        return try await get(url, as: type)
    }
}

public struct URLSessionNetworkClient: NetworkClient {
    private let session: URLSession
    private let decoder: JSONDecoder

    public init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }

    public func get<T: Decodable>(_ url: URL, as type: T.Type) async throws -> T {
        let (data, response) = try await session.data(from: url)

        guard let http = response as? HTTPURLResponse else {
            throw CurrencyError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw CurrencyError.httpStatus(http.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw CurrencyError.decodingFailed(underlying: error)
        }
    }
}
