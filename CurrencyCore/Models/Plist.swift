//
//  Plist.swift
//  CurrencyCore
//
//  Created by Kirill Kirilenko on 29/04/2023.
//

struct Plist<T: Decodable>: Decodable {
    let currencies: [T]
}
