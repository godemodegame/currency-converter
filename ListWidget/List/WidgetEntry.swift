//
//  WidgetEntry.swift
//  CurrencyConverter
//
//  Created by Kirill Kirilenko on 03/05/2023.
//

import WidgetKit

struct WidgetEntry: TimelineEntry {
    let date: Date
    let currencies: [CurrencyModel]
    let error: Error?
    let configuration: ConfigurationIntent
}

struct CurrencyModel: Identifiable, Equatable {
    let id: UUID = UUID()
    let name: String
    let image: WidgetImage?
    let baseName: String
    let rate: Double
}

enum WidgetImage: Equatable {
    case flag(String)
    case image(Data)
}
