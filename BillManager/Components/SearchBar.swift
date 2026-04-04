import SwiftUI

// MARK: - SearchBar

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "搜索账单..."
    var onCommit: (() -> Void)? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: AppSpacing.spacing2) {
            // 主搜索栏
            HStack(spacing: AppSpacing.spacing2) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(AppColors.textTertiary)

                TextField(placeholder, text: $text)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(AppColors.textPrimary)
                    .focused($isFocused)
                    .onSubmit { onCommit?() }

                if !text.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            text = ""
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .padding(.horizontal, AppSpacing.spacing3)
            .frame(height: 40)
            .background(
                Capsule()
                    .fill(AppColors.backgroundAlt)
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                isFocused ? AppColors.primary : Color.clear,
                                lineWidth: 1.5
                            )
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)

            // 取消按钮（聚焦时出现）
            if isFocused {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isFocused = false
                        text = ""
                    }
                } label: {
                    Text("取消")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(AppColors.primary)
                }
                .buttonStyle(.plain)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: AppSpacing.spacing4) {
        SearchBar(text: .constant(""))
        SearchBar(text: .constant("餐饮"))
    }
    .padding(AppSpacing.spacing4)
    .background(AppColors.background)
    .preferredColorScheme(.light)
}
