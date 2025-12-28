//
//  Color+Ocean.swift
//  CurrencyConverter
//
//  Design System - Color Extensions
//

import SwiftUI

extension Color {
    /// Dynamic ocean primary color - adapts to light/dark mode
    static var oceanPrimary: Color {
        Color("OceanPrimary", bundle: nil)
    }

    /// Dynamic ocean accent color - adapts to light/dark mode
    static var oceanAccent: Color {
        Color("OceanAccent", bundle: nil)
    }
}

extension LinearGradient {
    /// Ocean gradient for backgrounds - top to bottom
    static func oceanBackground(for colorScheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: colorScheme == .dark ?
                [Color.deepSea, Color.oceanNight] :
                [Color.foamWhite, Color.waveBlue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Primary button gradient - ocean blue to teal
    static var oceanButton: LinearGradient {
        LinearGradient(
            colors: [Color.oceanBluePrimary, Color.oceanTeal],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// Glass border gradient - subtle white gradient
    static func glassBorder(opacity: Double = 0.3) -> LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(opacity),
                Color.white.opacity(opacity * 0.3)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
