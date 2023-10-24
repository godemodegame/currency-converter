//
//  CryptoWorker.swift
//  CurrencyCore
//
//  Created by Kirill Kirilenko on 03/05/2023.
//

public protocol CryptoCurrencyWorker: AnyObject {
    func prepareCurrencies(_ array: [DedustResponse]) throws -> [Currency]
}

public final class CryptoWorker: CryptoCurrencyWorker {
    private let plistFileUrl: URL?

    public init() {
        plistFileUrl = Bundle.main.url(
            forResource: "CryptoInfo",
            withExtension: "plist"
        )
    }

    public func prepareCurrencies(_ array: [DedustResponse]) throws -> [Currency] {
        guard let plistFileUrl else {
            throw CurrencyError.missingPlistFile
        }
        let data = try Data(contentsOf: plistFileUrl)
        let currencyPlist = try PropertyListDecoder()
            .decode(Plist<CryptoInfo>.self, from: data)
        return array.compactMap { crypto in
            let info = currencyPlist.currencies.first { $0.code == crypto.symbol }
            if let info, let image = URL(string: info.imageUrl) {
                return Currency(
                    name: info.name,
                    imageSource: .image(image),
                    code: crypto.symbol,
                    rate: 1 / crypto.price,
                    type: .crypto
                )
            } else {
                return nil
            }
        }
    }
}
