import SwiftUI

// MARK: - AppColors

struct AppColors {
    // MARK: Primary Colors
    static let primary       = Color(hex: "#F59E0B")
    static let primaryLight  = Color(hex: "#FCD34D")
    static let primaryDark   = Color(hex: "#D97706")
    static let primarySurface = Color(hex: "#FFFBEB")

    // MARK: Semantic Colors
    static let income        = Color(hex: "#10B981")
    static let incomeLight   = Color(hex: "#D1FAE5")
    static let expense       = Color(hex: "#F43F5E")
    static let expenseLight  = Color(hex: "#FFE4E8")
    static let balance       = Color(hex: "#F59E0B")
    static let success       = Color(hex: "#22C55E")
    static let warning       = Color(hex: "#F97316")
    static let error         = Color(hex: "#EF4444")
    static let info          = Color(hex: "#3B82F6")

    // MARK: Background Colors
    static let background        = Color(hex: "#FAFAF9")
    static let backgroundAlt     = Color(hex: "#F5F5F4")
    static let cardBackground    = Color.white
    static let backgroundTertiary = Color(hex: "#E7E5E4")

    // MARK: Text Colors
    static let textPrimary     = Color(hex: "#1C1917")
    static let textSecondary   = Color(hex: "#78716C")
    static let textTertiary    = Color(hex: "#A8A29E")
    static let textPlaceholder = Color(hex: "#D6D3D1")
    static let textOnPrimary   = Color.white
    static let textLink        = Color(hex: "#F59E0B")

    // MARK: Warm Accent Colors
    static let accentCoral  = Color(hex: "#FB923C")
    static let accentRose   = Color(hex: "#FB7185")
    static let accentSand   = Color(hex: "#FDE68A")
    static let accentBrown  = Color(hex: "#92400E")
}

// MARK: - AppTypography

struct AppTypography {
    /// 大金额数字展示 40pt Heavy
    static let display = Font.system(size: 40, weight: .heavy, design: .rounded)
    /// 记账输入 48pt Bold
    static let input   = Font.system(size: 48, weight: .bold,  design: .rounded)
    /// 页面主标题 H1
    static let h1      = Font.system(size: 28, weight: .bold,  design: .default)
    /// 卡片/区块标题 H2
    static let h2      = Font.system(size: 22, weight: .semibold, design: .default)
    /// 列表主要信息 H3
    static let h3      = Font.system(size: 18, weight: .semibold, design: .default)
    /// 二级标题 H4
    static let h4      = Font.system(size: 16, weight: .medium, design: .default)
    /// 正文 Body
    static let body    = Font.system(size: 16, weight: .regular, design: .default)
    /// 次要正文 Body Small
    static let bodySm  = Font.system(size: 14, weight: .regular, design: .default)
    /// 辅助信息 Caption
    static let caption = Font.system(size: 12, weight: .regular, design: .default)
    /// 极小标注 Caption Small
    static let captionSm = Font.system(size: 10, weight: .regular, design: .default)

    // MARK: Amount Fonts (Rounded + MonospacedDigit)
    /// 大金额（首页汇总）40pt Heavy
    static let amountLarge  = Font.system(size: 40, weight: .heavy,   design: .rounded)
    /// 中金额（列表汇总）22pt Semibold
    static let amountMedium = Font.system(size: 22, weight: .semibold, design: .rounded)
    /// 小金额（列表行）16pt Semibold
    static let amountSmall  = Font.system(size: 16, weight: .semibold, design: .rounded)
    /// 微型金额（徽章）12pt Medium
    static let amountMicro  = Font.system(size: 12, weight: .medium,  design: .rounded)
}

// MARK: - AppSpacing

struct AppSpacing {
    /// 4pt
    static let spacing1: CGFloat  = 4
    /// 8pt
    static let spacing2: CGFloat  = 8
    /// 12pt
    static let spacing3: CGFloat  = 12
    /// 16pt（标准间距）
    static let spacing4: CGFloat  = 16
    /// 20pt
    static let spacing5: CGFloat  = 20
    /// 24pt
    static let spacing6: CGFloat  = 24
    /// 32pt（页面水平边距）
    static let spacing8: CGFloat  = 32
    /// 40pt
    static let spacing10: CGFloat = 40
    /// 48pt
    static let spacing12: CGFloat = 48

    /// 页面水平标准边距
    static let pageHorizontal: CGFloat = 16
}

// MARK: - AppCornerRadius

struct AppCornerRadius {
    /// 4pt — 标签、角标、小徽章
    static let xs:    CGFloat = 4
    /// 8pt — 输入框、小按钮、图标背景
    static let sm:    CGFloat = 8
    /// 12pt — 列表行、次要卡片
    static let md:    CGFloat = 12
    /// 16pt — 标准卡片
    static let lg:    CGFloat = 16
    /// 24pt — 大卡片、底部 Sheet
    static let xl:    CGFloat = 24
    /// 32pt — 浮动按钮、大模态卡片
    static let xxl:   CGFloat = 32
    /// 999pt — 胶囊形按钮
    static let full:  CGFloat = 999

    // Legacy aliases for backward compatibility
    static let small:       CGFloat = 8
    static let medium:      CGFloat = 16
    static let large:       CGFloat = 24
    static let extraLarge:  CGFloat = 40
}

// MARK: - AppShadow

struct AppShadow {
    struct ShadowConfig {
        let color:   Color
        let opacity: Double
        let radius:  CGFloat
        let x:       CGFloat
        let y:       CGFloat

        var resolvedColor: Color { color.opacity(opacity) }
    }

    /// 轻阴影 — 卡片、列表项悬浮
    static let light = ShadowConfig(
        color:   Color(hex: "#92400E"),
        opacity: 0.06,
        radius:  8,
        x:       0,
        y:       2
    )

    /// 标准阴影 — 主要卡片、浮动元素
    static let standard = ShadowConfig(
        color:   Color(hex: "#92400E"),
        opacity: 0.10,
        radius:  16,
        x:       0,
        y:       4
    )

    /// 强调阴影 — 主按钮、FAB 悬浮
    static let emphasis = ShadowConfig(
        color:   Color(hex: "#F59E0B"),
        opacity: 0.30,
        radius:  20,
        x:       0,
        y:       8
    )

    /// 底部栏阴影
    static let bottomBar = ShadowConfig(
        color:   Color(hex: "#1C1917"),
        opacity: 0.08,
        radius:  12,
        x:       0,
        y:       -4
    )
}

// MARK: - AppGradients

struct AppGradients {
    /// 主色调暖色渐变（topLeading → bottomTrailing）
    static let primary = LinearGradient(
        colors: [AppColors.primaryLight, AppColors.primary],
        startPoint: .topLeading,
        endPoint:   .bottomTrailing
    )

    /// 主色调渐变（从亮到暗，水平方向）
    static let primaryHorizontal = LinearGradient(
        colors: [AppColors.primaryLight, AppColors.primaryDark],
        startPoint: .leading,
        endPoint:   .trailing
    )

    /// 暖沙背景渐变
    static let warmBackground = LinearGradient(
        colors: [AppColors.accentSand.opacity(0.4), AppColors.primarySurface],
        startPoint: .topLeading,
        endPoint:   .bottomTrailing
    )

    /// 收入渐变
    static let income = LinearGradient(
        colors: [AppColors.income, Color(hex: "#059669")],
        startPoint: .topLeading,
        endPoint:   .bottomTrailing
    )

    /// 支出渐变
    static let expense = LinearGradient(
        colors: [AppColors.expense, Color(hex: "#E11D48")],
        startPoint: .topLeading,
        endPoint:   .bottomTrailing
    )
}

// MARK: - View Shadow Extensions

extension View {
    /// 轻阴影
    func shadowLight() -> some View {
        let s = AppShadow.light
        return self.shadow(color: s.resolvedColor, radius: s.radius, x: s.x, y: s.y)
    }

    /// 标准阴影
    func shadowStandard() -> some View {
        let s = AppShadow.standard
        return self.shadow(color: s.resolvedColor, radius: s.radius, x: s.x, y: s.y)
    }

    /// 强调阴影（主按钮、FAB）
    func shadowEmphasis() -> some View {
        let s = AppShadow.emphasis
        return self.shadow(color: s.resolvedColor, radius: s.radius, x: s.x, y: s.y)
    }

    /// 底部栏阴影
    func shadowBottomBar() -> some View {
        let s = AppShadow.bottomBar
        return self.shadow(color: s.resolvedColor, radius: s.radius, x: s.x, y: s.y)
    }
}
