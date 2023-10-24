//
//  ListWidget.swift
//  ListWidget
//
//  Created by Kirill Kirilenko on 03/05/2023.
//

import WidgetKit
import SwiftUI
import Intents

struct ListWidgetEntryView: View {
    var entry: ListWidgetProvider.Entry

    var body: some View {
        VStack(spacing: 0) {
            ForEach(entry.currencies) { currency in
                HStack {
                    Text("1 \(currency.name) =")
                        .font(.system(size: 16).bold())
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(currency.rate.formatted(
                            .number.precision(
                                .integerAndFractionLength(
                                    integerLimits: 1...,
                                    fractionLimits: ...2
                                )
                            )
                        )).font(.system(size: 14))
                        Text("\(currency.baseName)")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 5)
                if entry.currencies.firstIndex(of: currency) != 2 {
                    Rectangle()
                        .frame(maxWidth: .infinity)
                        .frame(height: 1)
                        .padding(.horizontal)
                        .foregroundColor(.gray.opacity(0.4))
                }
            }
        }
    }
}

struct ListWidget: Widget {
    var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: "ListWidget",
            intent: ConfigurationIntent.self,
            provider: ListWidgetProvider()
        ) { entry in
            ListWidgetEntryView(entry: entry)
        }
        .supportedFamilies([.systemSmall])
        .configurationDisplayName("Ocean Widget")
        .description("Widget with list of your favorite currencies")
    }
}
