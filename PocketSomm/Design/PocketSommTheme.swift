//
//  PocketSommTheme.swift
//  PocketSomm
//
//  Defines a centralized design system for colors, typography, and reusable
//  styles. Import this file wherever UI components are created to ensure
//  consistent look and feel across the app. To customize the palette,
//  modify the colors below or add asset catalog entries matching the
//  specified names.
//

import SwiftUI

/// A namespace encapsulating all design tokens used throughout the app.
enum PocketSommTheme {
    /// Primary brand color used for call‑to‑action buttons and highlights.
    static let primaryColor = Color("PrimaryColor", bundle: .main)

    /// Secondary accent color used for less prominent highlights or badges.
    static let secondaryColor = Color("SecondaryColor", bundle: .main)

    /// Background color for the app's views.
    static let backgroundColor = Color("BackgroundColor", bundle: .main)

    /// Card background color, slightly translucent to allow layering on the main background.
    static let cardBackgroundColor = Color(.systemBackground).opacity(0.9)

    /// Accent color for tags or small highlights.
    static let accentColor = Color("AccentColor", bundle: .main)

    /// Default corner radius for buttons, cards, and other components.
    static let cornerRadius: CGFloat = 12

    /// Default spacing used between elements.
    static let spacing: CGFloat = 16
}

/// A button style representing the primary call‑to‑action. Applies
/// consistent padding, corner radius, and background colors. Use via
/// `.buttonStyle(PrimaryButtonStyle())` on buttons.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(PocketSommTheme.primaryColor.opacity(configuration.isPressed ? 0.8 : 1.0))
            .foregroundColor(.white)
            .cornerRadius(PocketSommTheme.cornerRadius)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

/// A simple tag or chip view used to display small pieces of information
/// such as grapes, countries, or regions. Colors and font sizes can be
/// adjusted to match the theme.
struct TagChip: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(PocketSommTheme.accentColor.opacity(0.2))
            .foregroundColor(PocketSommTheme.accentColor)
            .cornerRadius(PocketSommTheme.cornerRadius / 2)
    }
}

extension View {
    /// Applies a card style to the view with padding, background,
    /// rounded corners, and a light shadow. Use this modifier on
    /// groups of content that need to stand out against the background.
    ///
    /// We avoid naming this `cardStyle()` to prevent collisions with any
    /// other `cardStyle` definitions that might exist in the project. Use
    /// `.pocketCardStyle()` instead of `.cardStyle()` on your views.
    func pocketCardStyle() -> some View {
        self
            .padding()
            .background(PocketSommTheme.cardBackgroundColor)
            .cornerRadius(PocketSommTheme.cornerRadius)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
