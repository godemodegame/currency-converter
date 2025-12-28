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
        HStack(spacing: OceanSpacing.md) {
            // Currency icon/flag
            if case .flag(let flag) = currency.imageSource {
                Text(flag)
                    .font(.system(size: 36))
            } else if case .image(let url) = currency.imageSource {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                        )
                } placeholder: {
                    ProgressView()
                        .frame(width: 36, height: 36)
                }
            }

            // Currency name
            Text(currency.name)
                .font(.body)
                .fontWeight(.medium)

            Spacer()

            // Rate display or bookmark
            if type == .base {
                VStack(alignment: .trailing, spacing: OceanSpacing.xxs) {
                    Text(
                        currency.rate
                            .formatted()
                    )
                    .font(.body)
                    .fontWeight(.semibold)
                    Text(currency.code)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if case .selection(let isSelected) = type {
                Image(systemName: isSelected ? "bookmark.fill" : "bookmark")
                    .foregroundColor(isSelected ? .oceanTeal : .secondary)
                    .font(.system(size: 20))
            }
        }
        .padding(.vertical, OceanSpacing.sm)
        .contentShape(Rectangle())
    }
}

enum CurrencyRowType: Equatable {
    case base
    case selection(Bool)
}
