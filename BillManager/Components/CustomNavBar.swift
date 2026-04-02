import SwiftUI

struct CustomNavBar<LeftContent: View, RightContent: View>: View {
    let title: String
    var leftContent: () -> LeftContent
    var rightContent: () -> RightContent

    init(
        title: String,
        @ViewBuilder leftContent: @escaping () -> LeftContent = { EmptyView() },
        @ViewBuilder rightContent: @escaping () -> RightContent = { EmptyView() }
    ) {
        self.title = title
        self.leftContent = leftContent
        self.rightContent = rightContent
    }

    var body: some View {
        ZStack {
            HStack {
                leftContent()
                Spacer()
            }

            HStack {
                Spacer()
                rightContent()
            }

            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(AppColors.background)
    }
}

struct NavBarButton: View {
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(color)
                )
        }
    }
}

struct NavBarMenuButton<T: View>: View {
    let icon: String
    let color: Color
    let content: () -> T

    init(
        icon: String,
        color: Color,
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
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(color.opacity(0.15))
            )
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        CustomNavBar(
            title: "账本",
            leftContent: {
                Button {} label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                }
            },
            rightContent: {
                NavBarButton(icon: "plus", color: AppColors.primary) {}
            }
        )

        Spacer()
    }
    .background(AppColors.background)
}
