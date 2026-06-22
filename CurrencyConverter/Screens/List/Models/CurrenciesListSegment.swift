//
//  CurrenciesListSegment.swift
//  CurrencyConverter
//
//  Created by Kirill Kirilenko on 29/04/2023.
//

enum CurrenciesListSegment: String, CaseIterable {
    case favorite
    case all
    case fiat
    case crypto

    /// User-facing tab label. The `rawValue` stays `fiat` (filtering logic,
    /// analytics, persistence) while the UI shows a non-jargon term.
    var title: String {
        switch self {
        case .favorite: return "Favorite"
        case .all: return "All"
        case .fiat: return "Cash"
        case .crypto: return "Crypto"
        }
    }
}
