//
//  ExchangeRatesResponse.swift
//  CurrencyCore
//
//  Created by Kirill Kirilenko on 29/04/2023.
//

public struct ExchangeRatesResponse: Decodable {
    public let rates: [String: Double]
}
