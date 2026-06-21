//
//  CoinMapping.swift
//  CurrencyCore
//
//  Single source of truth mapping app currency codes to CoinGecko IDs.
//

enum CoinMapping {
    /// Canonical mapping: app currency code -> CoinGecko id.
    /// This is the only place coin pairs should be edited; the inverse is derived.
    static let appCodeToCoinGeckoId: [String: String] = [
        "BTC": "bitcoin",
        "ETH": "ethereum",
        "USDT": "tether",
        "USDC": "usd-coin",
        "UNI": "uniswap",
        "TUSD": "true-usd",
        "TRX": "tron",
        "TON": "the-open-network",
        "SOL": "solana",
        "MATIC": "polygon-ecosystem-token",
        "DAI": "dai",
        "AAVE": "aave",
        "XRP": "ripple",
        "BNB": "binancecoin",
        "ADA": "cardano",
        "DOGE": "dogecoin",
        "AVAX": "avalanche-2",
        "DOT": "polkadot",
        "LINK": "chainlink",
        "SHIB": "shiba-inu",
        "LTC": "litecoin",
        "BCH": "bitcoin-cash",
        "ATOM": "cosmos",
        "PEPE": "pepe",
        "CAKE": "pancakeswap-token",
        "CRV": "curve-dao-token",
        "SUSHI": "sushi",
        "COMP": "compound-governance-token",
        "MKR": "maker"
    ]

    /// Derived inverse: CoinGecko id -> app currency code.
    /// `uniqueKeysWithValues` traps at launch if two app codes ever map to the
    /// same CoinGecko id, surfacing map drift instead of silently dropping a coin.
    static let coinGeckoIdToAppCode: [String: String] =
        Dictionary(uniqueKeysWithValues: appCodeToCoinGeckoId.map { ($0.value, $0.key) })
}
