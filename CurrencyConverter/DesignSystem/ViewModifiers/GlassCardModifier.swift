//
//  GlassCardModifier.swift
//  CurrencyConverter
//
//  Design System - Glass Card Modifier
//

import SwiftUI

struct GlassCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let padding: CGFloat
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    Color.white.opacity(colorScheme == .dark ? 0.3 : 0.15)
                        .blur(radius: OceanBlur.medium)

                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            LinearGradient.glassBorder(opacity: 0.3),
                            lineWidth: 1
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(
                color: Color.black.opacity(0.1),
                radius: OceanShadow.card.radius,
                x: OceanShadow.card.x,
                y: OceanShadow.card.y
            )
    }
}

extension View {
    /// Applies glass card effect with padding
    func glassCard(
        cornerRadius: CGFloat = OceanRadius.md,
        padding: CGFloat = OceanSpacing.md
    ) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, padding: padding))
    }
}
