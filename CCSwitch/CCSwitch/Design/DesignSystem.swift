import SwiftUI

struct DesignSystem {
    struct Colors {
        static let background = Color("AppBackground") // Fallback to system if asset not present
        static let surface = Color(NSColor.controlBackgroundColor)
        static let secondarySurface = Color(NSColor.textBackgroundColor)
        static let accent = Color.blue
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
    }
    
    struct Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xLarge: CGFloat = 32
    }
    
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
    }
    
    struct Fonts {
        static let title = Font.system(size: 24, weight: .bold)
        static let headline = Font.system(size: 18, weight: .semibold)
        static let body = Font.system(size: 14, weight: .regular)
        static let caption = Font.system(size: 12, weight: .medium)
    }
}

// MARK: - View Modifiers

struct ModernCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(DesignSystem.Spacing.medium)
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.CornerRadius.medium)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

extension View {
    func modernCardStyle() -> some View {
        self.modifier(ModernCardStyle())
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Fonts.body.weight(.medium))
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(DesignSystem.Colors.accent)
            .foregroundColor(.white)
            .cornerRadius(DesignSystem.CornerRadius.small)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Fonts.body.weight(.medium))
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color.gray.opacity(0.1))
            .foregroundColor(DesignSystem.Colors.textPrimary)
            .cornerRadius(DesignSystem.CornerRadius.small)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}
