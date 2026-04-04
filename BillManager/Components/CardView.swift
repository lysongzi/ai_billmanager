import SwiftUI

// MARK: - ShadowLevel

enum ShadowLevel {
    case none
    case light
    case standard
}

// MARK: - CardView

struct CardView<Content: View>: View {
    var padding: CGFloat = AppSpacing.spacing4
    var cornerRadius: CGFloat = AppCornerRadius.lg
    var shadowLevel: ShadowLevel = .light
    var hasBorder: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppColors.cardBackground)
                    .overlay(
                        hasBorder
                            ? RoundedRectangle(cornerRadius: cornerRadius)
                                .strokeBorder(AppColors.backgroundTertiary, lineWidth: 0.5)
                            : nil
                    )
                    .applyShadow(shadowLevel)
            )
    }
}

// MARK: - Shadow Modifier

private extension View {
    @ViewBuilder
    func applyShadow(_ level: ShadowLevel) -> some View {
        switch level {
        case .none:
            self
        case .light:
            self.shadowLight()
        case .standard:
            self.shadowStandard()
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: AppSpacing.spacing4) {
            CardView {
                VStack(alignment: .leading, spacing: AppSpacing.spacing2) {
                    Text("标准卡片（轻阴影）")
                        .font(AppTypography.h4)
                        .foregroundColor(AppColors.textPrimary)
                    Text("这是卡片的内容区域，展示基本的卡片样式。")
                        .font(AppTypography.bodySm)
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            CardView(cornerRadius: AppCornerRadius.xl, shadowLevel: .standard) {
                VStack(alignment: .leading, spacing: AppSpacing.spacing2) {
                    Text("大圆角卡片（标准阴影）")
                        .font(AppTypography.h4)
                        .foregroundColor(AppColors.textPrimary)
                    Text("适用于主要内容卡片、统计摘要区域。")
                        .font(AppTypography.bodySm)
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            CardView(shadowLevel: .none, hasBorder: true) {
                VStack(alignment: .leading, spacing: AppSpacing.spacing2) {
                    Text("带描边卡片（无阴影）")
                        .font(AppTypography.h4)
                        .foregroundColor(AppColors.textPrimary)
                    Text("适用于白底页面上需要区分边界的卡片。")
                        .font(AppTypography.bodySm)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .padding(AppSpacing.spacing4)
    }
    .background(AppColors.background)
    .preferredColorScheme(.light)
}
