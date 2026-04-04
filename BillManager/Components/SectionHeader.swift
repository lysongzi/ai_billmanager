import SwiftUI

// MARK: - SectionHeader

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var actionTitle: String? = nil
    var showAccentBar: Bool = false
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.spacing2) {
            // 左侧装饰线
            if showAccentBar {
                RoundedRectangle(cornerRadius: AppCornerRadius.xs)
                    .fill(AppColors.primary)
                    .frame(width: 3, height: 18)
            }

            // 标题区域
            VStack(alignment: .leading, spacing: AppSpacing.spacing1) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
            }

            Spacer()

            // 右侧操作按钮
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(AppColors.primary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, AppSpacing.spacing6)
        .padding(.bottom, AppSpacing.spacing3)
        .padding(.horizontal, AppSpacing.pageHorizontal)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        SectionHeader(title: "本月账单", actionTitle: "查看全部", action: {})

        SectionHeader(title: "支出分类", subtitle: "共 8 类", showAccentBar: true)

        SectionHeader(
            title: "最近记录",
            subtitle: "今日 3 笔",
            actionTitle: "更多",
            showAccentBar: true,
            action: {}
        )

        SectionHeader(title: "常规设置")
    }
    .background(AppColors.background)
    .preferredColorScheme(.light)
}
