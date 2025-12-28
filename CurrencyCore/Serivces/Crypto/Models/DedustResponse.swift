//
//  DedustResponse.swift
//  CurrencyCore
//
//  Created by Kirill Kirilenko on 03/05/2023.
//

public struct CoinGeckoResponse: Decodable {
    let usd: Double
}

public typealias DedustResponse = CoinGeckoResponse
