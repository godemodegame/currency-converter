//
//  CurrencyRow.swift
//  CurrencyConverter
//
//  Created by Kirill Kirilenko on 29/04/2023.
//

import SwiftUI
import CurrencyCore
import CachedAsyncImage

struct CurrencyRow: View {
    let currency: Currency
    let type: CurrencyRowType

    var body: some View {
        HStack {
            if case .flag(let flag) = currency.imageSource {
                Text(flag)
                    .font(.title)
            } else if case .image(let url) = currency.imageSource {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .frame(width: 30, height: 30)
                        .clipShape(Circle())
                } placeholder: {
                    ProgressView()
                        .frame(width: 30, height: 30)
                }
            }
            Text(currency.name)
            Spacer()
            if type == .base {
                VStack(alignment: .trailing) {
                    Text(
                        currency.rate
                            .formatted()
                    )
                    Text(currency.code)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else if case .selection(let isSelected) = type {
                Image(systemName: isSelected ? "bookmark.fill" : "bookmark")
            }
        }.padding(.vertical, 5)
    }
}

enum CurrencyRowType: Equatable {
    case base
    case selection(Bool)
}
