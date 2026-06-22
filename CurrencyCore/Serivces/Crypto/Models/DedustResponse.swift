//
//  DedustResponse.swift
//  CurrencyCore
//
//  Created by Kirill Kirilenko on 03/05/2023.
//

/// One row from CoinGecko's `/coins/markets` endpoint. Unlike the old
/// `/simple/price` shape, each row already carries the display name, symbol,
/// and icon URL, so the crypto list no longer needs a local id-map or a
/// bundled metadata plist.
public struct CoinGeckoMarket: Decodable {
    let symbol: String
    let name: String
    let image: String
    let currentPrice: Double?

    enum CodingKeys: String, CodingKey {
        case symbol, name, image
        case currentPrice = "current_price"
    }
}
