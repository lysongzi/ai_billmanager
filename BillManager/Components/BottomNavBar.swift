import SwiftUI

// MARK: - BottomNavBar

struct BottomNavBar: View {
    @Binding var selectedTab: Int
    var onAddTap: (() -> Void)? = nil

    private let tabs: [(icon: String, label: String)] = [
        (icon: "book.fill",       label: "账单"),
        (icon: "chart.pie.fill",  label: "统计"),
        (icon: "gearshape.fill",  label: "设置")
    ]

    var body: some View {
        ZStack(alignment: .top) {
            // 顶部分隔线
            Rectangle()
                .fill(AppColors.backgroundTertiary)
                .frame(height: 0.5)
                .zIndex(1)

            HStack(spacing: 0) {
                // 账单 Tab
                BottomNavItem(
                    icon: tabs[0].icon,
                    label: tabs[0].label,
                    isSelected: selectedTab == 0,
                    activeColor: AppColors.primary
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 0
                    }
                }

                // 统计 Tab
                BottomNavItem(
                    icon: tabs[1].icon,
                    label: tabs[1].label,
                    isSelected: selectedTab == 1,
                    activeColor: AppColors.primary
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 1
                    }
                }

                // FAB 占位
                Spacer()
                    .frame(width: 80)

                // 设置 Tab
                BottomNavItem(
                    icon: tabs[2].icon,
                    label: tabs[2].label,
                    isSelected: selectedTab == 2,
                    activeColor: AppColors.primary
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 2
                    }
                }
            }
            .padding(.horizontal, AppSpacing.spacing6)
            .padding(.vertical, AppSpacing.spacing2)
            .background(AppColors.cardBackground)
        }
        .overlay(alignment: .top) {
            // FAB 浮动记账按钮
            Button {
                onAddTap?()
            } label: {
                ZStack {
                    Circle()
                        .fill(AppGradients.primary)
                        .frame(width: 56, height: 56)
                        .shadowEmphasis()

                    Image(systemName: "plus")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(AppColors.textOnPrimary)
                }
            }
            .buttonStyle(.plain)
            .offset(y: -12)
        }
        .shadowBottomBar()
    }
}

// MARK: - BottomNavItem

private struct BottomNavItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let activeColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppSpacing.spacing1) {
                // 激活指示器
                RoundedRectangle(cornerRadius: AppCornerRadius.xs)
                    .fill(activeColor)
                    .frame(width: 16, height: 2)
                    .scaleEffect(x: isSelected ? 1 : 0)
                    .opacity(isSelected ? 1 : 0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)

                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isSelected ? activeColor : AppColors.textTertiary)
                    .scaleEffect(isSelected ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)

                Text(label)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(isSelected ? activeColor : AppColors.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.spacing1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()
        BottomNavBar(
            selectedTab: .constant(0),
            onAddTap: { print("add tapped") }
        )
    }
    .background(AppColors.background)
    .preferredColorScheme(.light)
}
