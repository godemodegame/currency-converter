//
//  ExchangeRatesResponse.swift
//  CurrencyCore
//
//  Created by Kirill Kirilenko on 29/04/2023.
//

public struct ExchangeRatesResponse: Decodable {
    public let amount: Double
    public let base: String
    public let date: String
    public let rates: [String: Double]
}
