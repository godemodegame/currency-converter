//
//  Jetton.swift
//  CurrencyCore
//
//  Created by Kirill Kirilenko on 03/05/2023.
//

struct Jetton: Decodable {
    let name: String
    let address: String
    let price: Price
}
