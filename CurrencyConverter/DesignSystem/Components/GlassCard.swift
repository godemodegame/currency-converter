//
//  GlassCard.swift
//  CurrencyConverter
//
//  Design System - Glass Card Component
//

import SwiftUI

struct GlassCard<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat

    init(
        cornerRadius: CGFloat = OceanRadius.md,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .glassCard(cornerRadius: cornerRadius)
    }
}

struct GlassCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: OceanSpacing.md) {
            GlassCard {
                VStack(spacing: OceanSpacing.xs) {
                    Text("Glass Card Example")
                        .font(.headline)
                    Text("This is a glassmorphism card with ocean theme")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }

            GlassCard(cornerRadius: OceanRadius.lg) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.coralAccent)
                    Text("Large Corner Radius")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(OceanSpacing.md)
        .oceanBackground()
    }
}
