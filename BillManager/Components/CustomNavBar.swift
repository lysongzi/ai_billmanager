import SwiftUI

// MARK: - NavBarStyle

enum NavBarStyle {
    case standard    // 17pt Semibold 居中
    case largeTitle  // 28pt Bold 左对齐
}

// MARK: - CustomNavBar

struct CustomNavBar<LeftContent: View, RightContent: View>: View {
    let title: String
    var style: NavBarStyle = .standard
    var showDivider: Bool = false
    var leftContent: () -> LeftContent
    var rightContent: () -> RightContent

    init(
        title: String,
        style: NavBarStyle = .standard,
        showDivider: Bool = false,
        @ViewBuilder leftContent: @escaping () -> LeftContent = { EmptyView() },
        @ViewBuilder rightContent: @escaping () -> RightContent = { EmptyView() }
    ) {
        self.title = title
        self.style = style
        self.showDivider = showDivider
        self.leftContent = leftContent
        self.rightContent = rightContent
    }

    var body: some View {
        VStack(spacing: 0) {
            if style == .standard {
                // 标准模式：标题居中
                ZStack {
                    HStack {
                        leftContent()
                        Spacer()
                    }

                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)

                    HStack {
                        Spacer()
                        rightContent()
                    }
                }
                .padding(.horizontal, AppSpacing.spacing5)
                .padding(.vertical, AppSpacing.spacing3)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
            } else {
                // 大标题模式：标题左对齐
                HStack(alignment: .bottom) {
                    Text(title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)

                    Spacer()

                    HStack(spacing: AppSpacing.spacing2) {
                        rightContent()
                    }
                }
                .padding(.horizontal, AppSpacing.pageHorizontal)
                .padding(.vertical, AppSpacing.spacing3)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 56)
            }

            // 分隔线（由外部控制是否显示）
            if showDivider {
                Rectangle()
                    .fill(AppColors.backgroundTertiary)
                    .frame(height: 0.5)
            }
        }
        .background(AppColors.cardBackground)
    }
}

// MARK: - NavBarButton

struct NavBarButton: View {
    let icon: String
    var color: Color = AppColors.primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.textOnPrimary)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(color)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - NavBarIconButton

struct NavBarIconButton: View {
    let icon: String
    var color: Color = AppColors.primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
                .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - NavBarMenuButton

struct NavBarMenuButton<T: View>: View {
    let icon: String
    var color: Color = AppColors.primary
    let content: () -> T

    init(
        icon: String,
        color: Color = AppColors.primary,
        @ViewBuilder content: @escaping () -> T
    ) {
        self.icon = icon
        self.color = color
        self.content = content
    }

    var body: some View {
        Menu {
            content()
        } label: {
            HStack(spacing: AppSpacing.spacing1) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, AppSpacing.spacing3)
            .padding(.vertical, AppSpacing.spacing2)
            .background(
                Capsule()
                    .fill(color.opacity(0.12))
            )
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        CustomNavBar(
            title: "账本",
            leftContent: {
                NavBarIconButton(icon: "chevron.left", action: {})
            },
            rightContent: {
                NavBarButton(icon: "plus", action: {})
            }
        )

        CustomNavBar(
            title: "账单统计",
            showDivider: true,
            rightContent: {
                HStack(spacing: AppSpacing.spacing1) {
                    NavBarIconButton(icon: "square.and.arrow.up", action: {})
                    NavBarMenuButton(icon: "slider.horizontal.3") {
                        Text("按日期排序")
                        Text("按金额排序")
                    }
                }
            }
        )

        CustomNavBar(
            title: "我的账本",
            style: .largeTitle,
            rightContent: {
                NavBarButton(icon: "plus", action: {})
            }
        )

        Spacer()
    }
    .background(AppColors.background)
    .preferredColorScheme(.light)
}
