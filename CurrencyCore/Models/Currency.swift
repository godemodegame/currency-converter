//
//  Currency.swift
//  CurrencyCore
//
//  Created by Kirill Kirilenko on 29/04/2023.
//

public struct Currency: Identifiable, Codable {
    public var id: String {
        code
    }

    public let name: String
    public let imageSource: ImageSource
    public let code: String
    public let rate: Double
    public let type: CurrencyType

    public init(
        name: String,
        imageSource: ImageSource,
        code: String,
        rate: Double,
        type: CurrencyType
    ) {
        self.name = name
        self.imageSource = imageSource
        self.code = code
        self.rate = rate
        self.type = type
    }
}
