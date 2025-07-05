import SwiftUI

extension Color {
    // MARK: - Modern Color Palette
    
    // Blues
    static let primaryBlue = Color(red: 0.2, green: 0.4, blue: 0.8)
    static let lightBlue = Color(red: 0.85, green: 0.92, blue: 1.0)
    static let accentBlue = Color(red: 0.3, green: 0.6, blue: 0.9)
    
    // Greys
    static let charcoalGrey = Color(red: 0.3, green: 0.3, blue: 0.3)
    static let lightGrey = Color(red: 0.95, green: 0.95, blue: 0.95)
    static let mediumGrey = Color(red: 0.8, green: 0.8, blue: 0.8)
    
    // Silvers
    static let silver = Color(red: 0.75, green: 0.75, blue: 0.75)
    static let lightSilver = Color(red: 0.9, green: 0.9, blue: 0.9)
    
    // Whites
    static let softWhite = Color(red: 0.98, green: 0.98, blue: 0.98)
    static let pureWhite = Color.white
    
    // MARK: - Semantic Colors
    
    // Backgrounds
    static let primaryBackground = Color.softWhite
    static let secondaryBackground = Color.lightGrey
    static let cardBackground = Color.pureWhite
    
    // Text Colors
    static let primaryText = Color.charcoalGrey
    static let secondaryText = Color.silver
    static let accentText = Color.primaryBlue
    
    // Interactive Elements
    static let buttonPrimary = Color.primaryBlue
    static let buttonSecondary = Color.lightSilver
    static let buttonTertiary = Color.lightBlue
    
    // System Colors
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
}

// MARK: - View Modifiers

struct ModernCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.cardBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct ModernButtonStyle: ViewModifier {
    let style: ButtonStyleType
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return Color.buttonPrimary
        case .secondary:
            return Color.buttonSecondary
        case .tertiary:
            return Color.buttonTertiary
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            return Color.pureWhite
        case .secondary:
            return Color.primaryText
        case .tertiary:
            return Color.accentText
        }
    }
}

enum ButtonStyleType {
    case primary
    case secondary
    case tertiary
}

extension View {
    func modernCard() -> some View {
        self.modifier(ModernCardStyle())
    }
    
    func modernButton(_ style: ButtonStyleType) -> some View {
        self.modifier(ModernButtonStyle(style: style))
    }
} 