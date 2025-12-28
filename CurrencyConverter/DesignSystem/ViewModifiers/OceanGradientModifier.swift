//
//  OceanGradientModifier.swift
//  CurrencyConverter
//
//  Design System - Ocean Gradient Background Modifier
//

import SwiftUI

struct OceanGradientModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        ZStack {
            // Base gradient
            LinearGradient.oceanBackground(for: colorScheme)
                .ignoresSafeArea()

            // Animated wave overlay (subtle)
            GeometryReader { geometry in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                (colorScheme == .dark ? Color.bioluminescenceTeal : Color.oceanTeal)
                                    .opacity(0.12),
                                Color.clear
                            ],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: geometry.size.width
                        )
                    )
            }
            .ignoresSafeArea()

            content
        }
    }
}

extension View {
    /// Applies ocean-themed gradient background
    func oceanBackground() -> some View {
        modifier(OceanGradientModifier())
    }
}
