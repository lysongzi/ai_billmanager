import SwiftUI

// MARK: - EmptyStateView

struct EmptyStateView: View {
    var iconName: String = "tray.fill"
    let title: String
    var subtitle: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: AppSpacing.spacing4) {
            Spacer().frame(minHeight: AppSpacing.spacing10)

            // 图标
            Image(systemName: iconName)
                .font(.system(size: 56, weight: .light))
                .foregroundColor(AppColors.textPlaceholder)
                .frame(width: 80, height: 80)

            // 文案
            VStack(spacing: AppSpacing.spacing2) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)

                if let subtitle {
                    Text(subtitle)
                        .font(AppTypography.bodySm)
                        .foregroundColor(AppColors.textTertiary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }

            // 操作按钮
            if let actionTitle, let action {
                PrimaryButton(
                    title: actionTitle,
                    style: .fixed,
                    size: .compact,
                    action: action
                )
                .padding(.top, AppSpacing.spacing2)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppSpacing.spacing8)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        EmptyStateView(
            iconName: "tray.fill",
            title: "暂无账单",
            subtitle: "点击右下角「+」按钮开始记录第一笔账单",
            actionTitle: "立即记账",
            action: {}
        )

        Divider()

        EmptyStateView(
            iconName: "chart.bar.xaxis",
            title: "暂无统计数据",
            subtitle: "记录账单后这里将显示收支分析"
        )
    }
    .background(AppColors.background)
    .preferredColorScheme(.light)
}
