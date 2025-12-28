//
//  GlassmorphismModifier.swift
//  CurrencyConverter
//
//  Design System - Glassmorphism Effect Modifier
//

import SwiftUI

struct GlassmorphismModifier: ViewModifier {
    let opacity: Double
    let blurRadius: CGFloat
    let cornerRadius: CGFloat
    let borderOpacity: Double
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Glass background with adaptive opacity
                    Color.white.opacity(colorScheme == .dark ? opacity * 2 : opacity)
                        .blur(radius: blurRadius)

                    // Subtle border for definition
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            LinearGradient.glassBorder(opacity: borderOpacity),
                            lineWidth: 1
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(
                color: Color.black.opacity(0.1),
                radius: OceanShadow.medium.radius,
                x: OceanShadow.medium.x,
                y: OceanShadow.medium.y
            )
    }
}

extension View {
    /// Applies glassmorphism effect with customizable parameters
    func glass(
        opacity: Double = 0.15,
        blur: CGFloat = OceanBlur.medium,
        cornerRadius: CGFloat = OceanRadius.md,
        borderOpacity: Double = 0.3
    ) -> some View {
        modifier(GlassmorphismModifier(
            opacity: opacity,
            blurRadius: blur,
            cornerRadius: cornerRadius,
            borderOpacity: borderOpacity
        ))
    }
}
