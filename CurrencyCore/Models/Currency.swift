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

public extension Currency {
    /// This currency's `rate` re-expressed against `base` for `amount` units.
    ///
    /// Both rates must share the same reference base (the canonical fetch base
    /// used by `CurrencyService`). The result is "units of `self` per `amount`
    /// units of `base`", which is exact because the shared base cancels out.
    func rate(against base: Currency, amount: Double = 1) -> Double {
        rate / base.rate * amount
    }

    /// A copy of this currency with `rate` re-expressed against `base`.
    func converted(against base: Currency, amount: Double = 1) -> Currency {
        Currency(
            name: name,
            imageSource: imageSource,
            code: code,
            rate: rate(against: base, amount: amount),
            type: type
        )
    }
}

public extension Sequence where Element == Currency {
    /// Re-expresses every currency in the sequence against `base`.
    func converted(against base: Currency, amount: Double = 1) -> [Currency] {
        map { $0.converted(against: base, amount: amount) }
    }
}
