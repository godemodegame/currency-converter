//
//  FloatingAnimationModifier.swift
//  CurrencyConverter
//
//  Design System - Floating Animation Modifier
//

import SwiftUI

struct FloatingAnimationModifier: ViewModifier {
    @State private var isFloating = false

    func body(content: Content) -> some View {
        content
            .offset(y: isFloating ? -10 : 10)
            .animation(
                .easeInOut(duration: 2)
                .repeatForever(autoreverses: true),
                value: isFloating
            )
            .onAppear {
                isFloating = true
            }
    }
}

extension View {
    /// Applies gentle up/down floating animation
    func floatingAnimation() -> some View {
        modifier(FloatingAnimationModifier())
    }
}
