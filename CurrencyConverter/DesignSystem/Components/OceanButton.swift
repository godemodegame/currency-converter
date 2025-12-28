//
//  OceanButton.swift
//  CurrencyConverter
//
//  Design System - Ocean Button Component
//

import SwiftUI

enum OceanButtonStyle {
    case primary
    case secondary
    case ghost
}

struct OceanButton: View {
    let title: String
    let style: OceanButtonStyle
    let action: () -> Void

    @State private var isPressed = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: {
            action()
        }) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(textColor)
                .padding(.vertical, OceanSpacing.md)
                .frame(maxWidth: .infinity)
        }
        .background(background)
        .cornerRadius(OceanRadius.md)
        .shadow(
            color: shadowColor,
            radius: isPressed ? OceanShadow.small.radius : OceanShadow.medium.radius,
            x: 0,
            y: isPressed ? OceanShadow.small.y : OceanShadow.medium.y
        )
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onTapGesture {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
        }
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .primary:
            LinearGradient.oceanButton
        case .secondary:
            Color.white.opacity(colorScheme == .dark ? 0.3 : 0.2)
                .blur(radius: OceanBlur.light)
        case .ghost:
            Color.clear
        }
    }

    private var textColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return .primary
        case .ghost:
            return colorScheme == .dark ? .bioluminescenceBlue : .oceanBluePrimary
        }
    }

    private var shadowColor: Color {
        switch style {
        case .primary:
            return Color.oceanBluePrimary.opacity(0.3)
        case .secondary, .ghost:
            return Color.black.opacity(0.1)
        }
    }
}

struct OceanButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            OceanButton(title: "Primary Button", style: .primary) {
                print("Primary tapped")
            }
            .padding(.horizontal, OceanSpacing.xxxl)

            OceanButton(title: "Secondary Button", style: .secondary) {
                print("Secondary tapped")
            }
            .padding(.horizontal, OceanSpacing.xxxl)

            OceanButton(title: "Ghost Button", style: .ghost) {
                print("Ghost tapped")
            }
            .padding(.horizontal, OceanSpacing.xxxl)
        }
        .oceanBackground()
    }
}
