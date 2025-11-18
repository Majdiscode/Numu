//
//  View+Elevation.swift
//  Numu
//
//  Elevation system and shadow modifiers inspired by shadcn UI design principles
//  Provides consistent depth and visual hierarchy across the app
//

import SwiftUI

// MARK: - Elevation Levels

/// Defines the elevation hierarchy for UI elements
/// Based on Material Design and shadcn UI principles
enum Elevation {
    case level0  // Flat (background, no elevation)
    case level1  // Cards, surfaces (subtle lift)
    case level2  // Floating elements, important cards
    case level3  // Modals, sheets (interruption)
    case level4  // Tooltips, dropdowns (highest priority)

    /// Shadow configuration for each elevation level
    var shadow: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat, opacity: Double) {
        switch self {
        case .level0:
            return (.black, 0, 0, 0, 0)
        case .level1:
            return (.black, 6, 0, 2, 0.15)  // Increased from 3/1/0.1
        case .level2:
            return (.black, 12, 0, 6, 0.18) // Increased from 8/4/0.12
        case .level3:
            return (.black, 20, 0, 10, 0.20) // Increased from 16/8/0.14
        case .level4:
            return (.black, 28, 0, 14, 0.22) // Increased from 24/12/0.16
        }
    }
}

// MARK: - Elevation Modifiers

extension View {
    /// Apply elevation shadow to a view
    /// - Parameter level: The elevation level to apply
    /// - Returns: View with appropriate shadow
    func elevation(_ level: Elevation) -> some View {
        let config = level.shadow
        return self.shadow(
            color: config.color.opacity(config.opacity),
            radius: config.radius,
            x: config.x,
            y: config.y
        )
    }

    /// Style a view as an elevated card with border and background
    /// - Parameters:
    ///   - elevation: The elevation level (default: .level1)
    ///   - cornerRadius: Corner radius (default: 16)
    ///   - padding: Internal padding (default: 16)
    /// - Returns: View styled as an elevated card
    func elevatedCard(
        elevation: Elevation = .level1,
        cornerRadius: CGFloat = 16,
        padding: CGFloat = 16
    ) -> some View {
        self
            .padding(padding)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .elevation(elevation)
    }

    /// Apply a subtle border to define edges (shadcn pattern)
    /// - Parameters:
    ///   - cornerRadius: Corner radius (default: 16)
    ///   - opacity: Border opacity (default: 0.08)
    /// - Returns: View with subtle border
    func cardBorder(cornerRadius: CGFloat = 16, opacity: Double = 0.08) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.primary.opacity(opacity), lineWidth: 1)
        )
    }
}

// MARK: - Interactive Depth Modifiers

extension View {
    /// Add press animation that scales down and increases shadow
    /// - Parameter isPressed: Binding to track press state
    /// - Returns: View with press interaction
    func pressableCard(isPressed: Binding<Bool>) -> some View {
        self
            .scaleEffect(isPressed.wrappedValue ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed.wrappedValue)
    }

    /// Add press animation with internal state management
    /// - Returns: View with press interaction
    func pressableCard() -> some View {
        PressableCardWrapper(content: self)
    }
}

// MARK: - Pressable Card Wrapper

/// Wrapper view that manages press state internally
private struct PressableCardWrapper<Content: View>: View {
    let content: Content
    @State private var isPressed = false

    var body: some View {
        content
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

// MARK: - Background Elevation Helpers

extension View {
    /// Apply a layered background with subtle depth
    /// - Returns: View with layered background
    func layeredBackground() -> some View {
        self
            .background(Color(.systemBackground))
            .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Scale Button Style

/// Button style that scales down on press without interfering with navigation
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
