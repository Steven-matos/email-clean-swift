import SwiftUI

extension Color {
    // MARK: - Modern Flat Color Palette (X.com inspired)
    
    // Primary Colors - Clean and minimal
    static let primaryBlue = Color(red: 0.0, green: 0.478, blue: 1.0)        // X blue
    static let accentBlue = Color(red: 0.0, green: 0.4, blue: 0.8)           // Darker blue
    static let lightBlue = Color(red: 0.9, green: 0.95, blue: 1.0)           // Very light blue
    
    // Grays - Flat and modern
    static let pureBlack = Color.black
    static let pureWhite = Color.white
    static let darkGray = Color(red: 0.15, green: 0.15, blue: 0.15)          // Near black
    static let mediumGray = Color(red: 0.6, green: 0.6, blue: 0.6)           // Medium gray
    static let lightGray = Color(red: 0.9, green: 0.9, blue: 0.9)            // Light gray
    static let ultraLightGray = Color(red: 0.97, green: 0.97, blue: 0.97)    // Almost white
    
    // Semantic Colors
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    
    // MARK: - Semantic Colors for Light Mode
    
    // Backgrounds - Clean and flat
    static let primaryBackground = Color.pureWhite
    static let secondaryBackground = Color.ultraLightGray
    static let cardBackground = Color.pureWhite
    static let surfaceBackground = Color.pureWhite
    
    // Text Colors - High contrast
    static let primaryText = Color.pureBlack
    static let secondaryText = Color.darkGray
    static let tertiaryText = Color.mediumGray
    static let accentText = Color.primaryBlue
    
    // Interactive Elements - Flat design
    static let buttonPrimary = Color.primaryBlue
    static let buttonSecondary = Color.ultraLightGray
    static let buttonTertiary = Color.pureWhite
    static let buttonDanger = Color.error
    
    // MARK: - Dark Mode Support
    
    // Dark Mode Backgrounds
    static let darkPrimaryBackground = Color.pureBlack
    static let darkSecondaryBackground = Color.darkGray
    static let darkCardBackground = Color.darkGray
    static let darkSurfaceBackground = Color.darkGray
    
    // Dark Mode Text
    static let darkPrimaryText = Color.pureWhite
    static let darkSecondaryText = Color.lightGray
    static let darkTertiaryText = Color.mediumGray
    static let darkAccentText = Color.primaryBlue
    
    // MARK: - Adaptive Colors
    
    static let adaptiveBackground = Color(UIColor.systemBackground)
    static let adaptiveSecondaryBackground = Color(UIColor.secondarySystemBackground)
    static let adaptiveText = Color(UIColor.label)
    static let adaptiveSecondaryText = Color(UIColor.secondaryLabel)
    static let adaptiveTertiaryText = Color(UIColor.tertiaryLabel)
}

// MARK: - Modern Flat View Modifiers

struct FlatCardStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(cardBackgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 0.5)
            )
    }
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color.darkCardBackground : Color.cardBackground
    }
    
    private var borderColor: Color {
        colorScheme == .dark ? Color.mediumGray.opacity(0.3) : Color.lightGray
    }
}

struct FlatButtonStyle: ViewModifier {
    let style: ButtonStyleType
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: style == .secondary ? 1 : 0)
            )
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return Color.buttonPrimary
        case .secondary:
            return colorScheme == .dark ? Color.darkCardBackground : Color.buttonSecondary
        case .tertiary:
            return Color.pureWhite
        case .danger:
            return Color.buttonDanger
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            return Color.pureWhite
        case .secondary:
            return colorScheme == .dark ? Color.darkPrimaryText : Color.primaryText
        case .tertiary:
            return colorScheme == .dark ? Color.darkAccentText : Color.accentText
        case .danger:
            return Color.pureWhite
        }
    }
    
    private var borderColor: Color {
        colorScheme == .dark ? Color.mediumGray.opacity(0.5) : Color.lightGray
    }
}

struct MinimalGradientStyle: ViewModifier {
    let type: GradientType
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(gradientBackground)
    }
    
    private var gradientBackground: LinearGradient {
        switch type {
        case .subtle:
            return LinearGradient(
                gradient: Gradient(colors: colorScheme == .dark ? 
                    [Color.darkPrimaryBackground, Color.darkSecondaryBackground] :
                    [Color.primaryBackground, Color.secondaryBackground]
                ),
                startPoint: .top,
                endPoint: .bottom
            )
        case .accent:
            return LinearGradient(
                gradient: Gradient(colors: [Color.lightBlue, Color.pureWhite]),
                startPoint: .top,
                endPoint: .bottom
            )
        case .hero:
            return LinearGradient(
                gradient: Gradient(colors: [Color.primaryBlue, Color.accentBlue]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

enum ButtonStyleType {
    case primary
    case secondary
    case tertiary
    case danger
}

enum GradientType {
    case subtle
    case accent
    case hero
}

extension View {
    func flatCard() -> some View {
        self.modifier(FlatCardStyle())
    }
    
    func flatButton(_ style: ButtonStyleType) -> some View {
        self.modifier(FlatButtonStyle(style: style))
    }
    
    func minimalGradient(_ type: GradientType) -> some View {
        self.modifier(MinimalGradientStyle(type: type))
    }
    
    // Adaptive text colors
    func adaptiveText(_ level: TextLevel = .primary) -> some View {
        self.foregroundColor(level.color)
    }
}

enum TextLevel {
    case primary
    case secondary
    case tertiary
    case accent
    
    var color: Color {
        switch self {
        case .primary:
            return Color.adaptiveText
        case .secondary:
            return Color.adaptiveSecondaryText
        case .tertiary:
            return Color.adaptiveTertiaryText
        case .accent:
            return Color.accentText
        }
    }
} 