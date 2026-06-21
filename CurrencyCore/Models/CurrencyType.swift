//
//  CurrencyType.swift
//  CurrencyCore
//
//  Created by Kirill Kirilenko on 29/04/2023.
//

public enum CurrencyType: String, Codable {
    case fiat
    case crypto

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        switch rawValue {
        case "fiat":
            self = .fiat
        case "crypto":
            self = .crypto
        default:
            // Throw on unknown types so invalid currencies are filtered out during deserialization.
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unknown currency type: \(rawValue)"
            )
        }
    }
}
