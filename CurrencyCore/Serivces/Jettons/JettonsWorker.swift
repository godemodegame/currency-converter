//
//  JettonsWorker.swift
//  CurrencyCore
//
//  Created by Kirill Kirilenko on 03/05/2023.
//

public protocol JettonsCurrencyWorker: AnyObject {
    func prepareCurrencies(_ response: RedoubtResponse, tonPrice: Double) throws -> [Currency]
}

public final class JettonsWorker: JettonsCurrencyWorker {
    private let plistFileUrl: URL?

    public init() {
        plistFileUrl = Bundle.main.url(
            forResource: "CryptoInfo",
            withExtension: "plist"
        )
    }

    public func prepareCurrencies(_ response: RedoubtResponse, tonPrice: Double) throws -> [Currency] {
        response.jettons.compactMap { jetton in
            if let image = makeUrl(from: jetton.address) {
                return Currency(
                    name: jetton.name,
                    imageSource: .image(image),
                    code: jetton.name,
                    rate: tonPrice / jetton.price.value,
                    type: .jetton
                )
            } else {
                return nil
            }
        }
    }

    func makeUrl(from address: String) -> URL? {
        URL(string: "https://api.redoubt.online/v1/jettons/image/\(address)")
    }
}
