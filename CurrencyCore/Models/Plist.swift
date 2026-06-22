//
//  Plist.swift
//  CurrencyCore
//
//  Created by Kirill Kirilenko on 29/04/2023.
//

import Foundation

struct Plist<T: Decodable>: Decodable {
    let currencies: [T]
}

extension Plist {
    /// Loads and decodes a `{ currencies: [T] }` plist bundled under `resource`.
    /// Throws `.missingPlistFile` when the resource is absent.
    static func load(resource: String, in bundle: Bundle = .main) throws -> Plist<T> {
        guard let url = bundle.url(forResource: resource, withExtension: "plist") else {
            throw CurrencyError.missingPlistFile
        }
        let data = try Data(contentsOf: url)
        return try PropertyListDecoder().decode(Plist<T>.self, from: data)
    }
}
