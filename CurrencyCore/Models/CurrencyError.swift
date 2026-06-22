//
//  CurrencyError.swift
//  CurrencyCore
//
//  Created by Kirill Kirilenko on 29/04/2023.
//

public enum CurrencyError: Error {
    case missingPlistFile
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case decodingFailed(underlying: Error)
}
