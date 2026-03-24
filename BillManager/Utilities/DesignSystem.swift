import SwiftUI

enum DesignSystem {
    
    // MARK: - Colors
    
    enum Colors {
        static let brandYellow = Color(hex: "#F6C744")
        static let brandYellowDark = Color(hex: "#E5B23D")
        
        static let expenseRed = Color(hex: "#F05A5A")
        static let incomeGreen = Color(hex: "#22B573")
        static let infoBlue = Color(hex: "#5B7CFA")
        static let warningOrange = Color(hex: "#F59E0B")
        
        static let background = Color(hex: "#F7F7F5")
        static let surface = Color(hex: "#FFFFFF")
        static let textPrimary = Color(hex: "#121212")
        static let textSecondary = Color(hex: "#6B7280")
        static let line = Color(hex: "#E9E9E7")
        static let textTertiary = Color(hex: "#9CA3AF")
    }
    
    // MARK: - Typography
    
    enum Typography {
        static let displayXL: Font = .system(size: 36, weight: .semibold)
        static let displayL: Font = .system(size: 28, weight: .semibold)
        static let h1: Font = .system(size: 28, weight: .bold)
        static let h2: Font = .system(size: 20, weight: .semibold)
        static let h3: Font = .system(size: 17, weight: .semibold)
        static let body: Font = .system(size: 15, weight: .regular)
        static let caption: Font = .system(size: 12, weight: .regular)
        
        static let amountLarge: Font = .system(size: 36, weight: .semibold, design: .rounded)
        static let amountMedium: Font = .system(size: 24, weight: .semibold, design: .rounded)
        static let amountSmall: Font = .system(size: 17, weight: .medium, design: .rounded)
    }
    
    // MARK: - Spacing
    
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        
        static let pageHorizontal: CGFloat = 20
        static let cardPadding: CGFloat = 16
        static let sectionSpacing: CGFloat = 24
    }
    
    // MARK: - Corner Radius
    
    enum CornerRadius {
        static let largeCard: CGFloat = 24
        static let card: CGFloat = 20
        static let small: CGFloat = 16
        static let button: CGFloat = 16
        static let tag: CGFloat = 12
    }
    
    // MARK: - Shadow
    
    enum Shadow {
        static let card = ShadowStyle(y: 6, blur: 18, opacity: 0.06)
        static let button = ShadowStyle(y: 4, blur: 12, opacity: 0.08)
    }
    
    struct ShadowStyle {
        let y: CGFloat
        let blur: CGFloat
        let opacity: Double
    }
    
    // MARK: - Component Sizes
    
    enum Size {
        static let buttonHeight: CGFloat = 52
        static let listRowHeight: CGFloat = 68
        static let iconSmall: CGFloat = 24
        static let iconMedium: CGFloat = 32
        static let iconLarge: CGFloat = 40
        static let iconXLarge: CGFloat = 50
    }
}

// MARK: - Color Extensions

extension Color {
    static let brandYellow = DesignSystem.Colors.brandYellow
    static let expenseRed = DesignSystem.Colors.expenseRed
    static let incomeGreen = DesignSystem.Colors.incomeGreen
    static let infoBlue = DesignSystem.Colors.infoBlue
    static let warningOrange = DesignSystem.Colors.warningOrange
    static let appBackground = DesignSystem.Colors.background
    static let surface = DesignSystem.Colors.surface
    static let textPrimary = DesignSystem.Colors.textPrimary
    static let textSecondary = DesignSystem.Colors.textSecondary
    static let textTertiary = DesignSystem.Colors.textTertiary
    static let line = DesignSystem.Colors.line
}

// MARK: - View Modifiers

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.surface)
            .cornerRadius(DesignSystem.CornerRadius.card)
            .shadow(
                color: Color.black.opacity(DesignSystem.Shadow.card.opacity),
                radius: DesignSystem.Shadow.card.blur / 2,
                x: 0,
                y: DesignSystem.Shadow.card.y
            )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.h3)
            .foregroundColor(DesignSystem.Colors.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: DesignSystem.Size.buttonHeight)
            .background(isEnabled ? DesignSystem.Colors.brandYellow : Color.gray.opacity(0.3))
            .cornerRadius(DesignSystem.CornerRadius.button)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct BlueButtonStyle: ButtonStyle {
    var isEnabled: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.h3)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: DesignSystem.Size.buttonHeight)
            .background(isEnabled ? DesignSystem.Colors.infoBlue : Color.gray.opacity(0.3))
            .cornerRadius(DesignSystem.CornerRadius.button)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
    
    func primaryButton(isEnabled: Bool = true) -> some View {
        buttonStyle(PrimaryButtonStyle(isEnabled: isEnabled))
    }
    
    func blueButton(isEnabled: Bool = true) -> some View {
        buttonStyle(BlueButtonStyle(isEnabled: isEnabled))
    }
}