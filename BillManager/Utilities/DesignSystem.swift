import SwiftUI

struct AppColors {
    static let primary = Color(red: 245/255, green: 158/255, blue: 11/255)
    static let primaryLight = Color(red: 252/255, green: 211/255, blue: 77/255)
    static let primaryDark = Color(red: 217/255, green: 119/255, blue: 6/255)
    
    static let background = Color(red: 250/255, green: 250/255, blue: 249/255)
    static let backgroundAlt = Color(red: 245/255, green: 245/255, blue: 244/255)
    static let cardBackground = Color.white
    
    static let textPrimary = Color(red: 28/255, green: 25/255, blue: 23/255)
    static let textSecondary = Color(red: 168/255, green: 162/255, blue: 158/255)
    static let textTertiary = Color(red: 120/255, green: 113/255, blue: 108/255)
    
    static let income = Color(red: 16/255, green: 185/255, blue: 129/255)
    static let expense = Color(red: 244/255, green: 63/255, blue: 94/255)
    static let balance = Color(red: 245/255, green: 158/255, blue: 11/255)
}

struct AppCornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let extraLarge: CGFloat = 40
}

struct AppShadows {
    static let card = Color.black.opacity(0.04)
    static let cardHover = Color.black.opacity(0.08)
    static let button = Color(red: 245/255, green: 158/255, blue: 11/255).opacity(0.3)
}