import SwiftUI

// MARK: - BadgeSize

enum BadgeSize {
    case xs  // 24×24pt, 12pt icon
    case sm  // 32×32pt, 16pt icon
    case md  // 44×44pt, 22pt icon  (standard)
    case lg  // 60×60pt, 28pt icon  (account cover)

    var containerSize: CGFloat {
        switch self {
        case .xs: return 24
        case .sm: return 32
        case .md: return 44
        case .lg: return 60
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .xs: return 12
        case .sm: return 16
        case .md: return 22
        case .lg: return 28
        }
    }
}

// MARK: - BadgeShape

enum BadgeShape {
    case circle
    case roundedSquare
}

// MARK: - IconBadge

struct IconBadge: View {
    let iconName: String
    var backgroundColor: Color = AppColors.primarySurface
    var iconColor: Color = AppColors.primary
    var size: BadgeSize = .md
    var shape: BadgeShape = .circle

    var body: some View {
        ZStack {
            Group {
                switch shape {
                case .circle:
                    Circle()
                        .fill(backgroundColor)
                case .roundedSquare:
                    RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                        .fill(backgroundColor)
                }
            }
            .frame(width: size.containerSize, height: size.containerSize)

            Image(systemName: iconName)
                .font(.system(size: size.iconSize, weight: .medium))
                .foregroundColor(iconColor)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: AppSpacing.spacing6) {
        Text("圆形").font(AppTypography.h4).foregroundColor(AppColors.textPrimary)
        HStack(spacing: AppSpacing.spacing4) {
            IconBadge(iconName: "book.fill", size: .xs)
            IconBadge(iconName: "book.fill", size: .sm)
            IconBadge(iconName: "book.fill", size: .md)
            IconBadge(iconName: "book.fill", size: .lg)
        }

        Text("圆角方形").font(AppTypography.h4).foregroundColor(AppColors.textPrimary)
        HStack(spacing: AppSpacing.spacing4) {
            IconBadge(iconName: "cart.fill", backgroundColor: AppColors.incomeLight, iconColor: AppColors.income, size: .sm, shape: .roundedSquare)
            IconBadge(iconName: "fork.knife", backgroundColor: AppColors.expenseLight, iconColor: AppColors.expense, size: .md, shape: .roundedSquare)
            IconBadge(iconName: "car.fill", backgroundColor: Color(hex: "#FEF3C7"), iconColor: AppColors.accentCoral, size: .lg, shape: .roundedSquare)
        }

        Text("多色示例").font(AppTypography.h4).foregroundColor(AppColors.textPrimary)
        HStack(spacing: AppSpacing.spacing3) {
            IconBadge(iconName: "house.fill", backgroundColor: AppColors.primarySurface, iconColor: AppColors.primary, size: .md)
            IconBadge(iconName: "heart.fill", backgroundColor: AppColors.expenseLight, iconColor: AppColors.expense, size: .md)
            IconBadge(iconName: "leaf.fill", backgroundColor: AppColors.incomeLight, iconColor: AppColors.income, size: .md)
            IconBadge(iconName: "bolt.fill", backgroundColor: Color(hex: "#FEF3C7"), iconColor: AppColors.warning, size: .md)
        }
    }
    .padding(AppSpacing.spacing4)
    .background(AppColors.background)
    .preferredColorScheme(.light)
}
