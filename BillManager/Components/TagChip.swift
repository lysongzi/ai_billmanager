import SwiftUI

// MARK: - ChipStyle

enum ChipStyle {
    case `default`    // backgroundAlt 背景，textSecondary 文字
    case selected     // primary 背景，白色文字
    case highlighted  // primarySurface 背景，primary 文字 + 描边
}

// MARK: - ChipSize

enum ChipSize {
    case standard // 32pt 高度
    case compact  // 28pt 高度
}

// MARK: - TagChip

struct TagChip: View {
    let title: String
    var iconName: String? = nil
    var style: ChipStyle = .default
    var size: ChipSize = .standard
    var onTap: (() -> Void)? = nil

    private var height: CGFloat {
        switch size {
        case .standard: return 32
        case .compact:  return 28
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .default:     return AppColors.backgroundAlt
        case .selected:    return AppColors.primary
        case .highlighted: return AppColors.primarySurface
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .default:     return AppColors.textSecondary
        case .selected:    return AppColors.textOnPrimary
        case .highlighted: return AppColors.primary
        }
    }

    private var strokeColor: Color {
        switch style {
        case .highlighted: return AppColors.primary
        default:           return .clear
        }
    }

    var body: some View {
        let content = HStack(spacing: AppSpacing.spacing1) {
            if let iconName {
                Image(systemName: iconName)
                    .font(.system(size: 14, weight: .medium))
            }
            Text(title)
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundColor(foregroundColor)
        .padding(.horizontal, AppSpacing.spacing3)
        .padding(.vertical, AppSpacing.spacing1 + 2)
        .frame(height: height)
        .background(
            Capsule()
                .fill(backgroundColor)
                .overlay(
                    Capsule()
                        .strokeBorder(strokeColor, lineWidth: 0.5)
                )
        )

        if let onTap {
            Button(action: onTap) {
                content
            }
            .buttonStyle(.plain)
        } else {
            content
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: AppSpacing.spacing4) {
        Text("默认态").font(AppTypography.caption).foregroundColor(AppColors.textTertiary)
        HStack(spacing: AppSpacing.spacing2) {
            TagChip(title: "餐饮", iconName: "fork.knife", onTap: {})
            TagChip(title: "交通", iconName: "car.fill", onTap: {})
            TagChip(title: "购物", onTap: {})
        }

        Text("选中态").font(AppTypography.caption).foregroundColor(AppColors.textTertiary)
        HStack(spacing: AppSpacing.spacing2) {
            TagChip(title: "本月", style: .selected, onTap: {})
            TagChip(title: "支出", iconName: "minus.circle.fill", style: .selected, onTap: {})
        }

        Text("高亮态").font(AppTypography.caption).foregroundColor(AppColors.textTertiary)
        HStack(spacing: AppSpacing.spacing2) {
            TagChip(title: "月视图", style: .highlighted, onTap: {})
            TagChip(title: "年视图", style: .highlighted, onTap: {})
        }

        Text("时间筛选（不可点击）").font(AppTypography.caption).foregroundColor(AppColors.textTertiary)
        HStack(spacing: AppSpacing.spacing2) {
            TagChip(title: "周", size: .compact)
            TagChip(title: "月", style: .selected, size: .compact)
            TagChip(title: "年", size: .compact)
        }
    }
    .padding(AppSpacing.spacing4)
    .background(AppColors.background)
    .preferredColorScheme(.light)
}
