import SwiftUI

// MARK: - PrimaryButton

enum PrimaryButtonStyle {
    case full    // 全宽
    case fixed   // 固定宽度（内容自适应）
}

enum PrimaryButtonSize {
    case standard // 52pt 高度
    case compact  // 44pt 高度
}

// MARK: - Press Scale Button Style

private struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var style: PrimaryButtonStyle = .full
    var size: PrimaryButtonSize = .standard
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    private var height: CGFloat {
        switch size {
        case .standard: return 52
        case .compact:  return 44
        }
    }

    var body: some View {
        Button {
            guard !isDisabled && !isLoading else { return }
            action()
        } label: {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(AppColors.textOnPrimary)
                } else {
                    HStack(spacing: AppSpacing.spacing2) {
                        if let icon {
                            Image(systemName: icon)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(AppColors.textOnPrimary)
                }
            }
            .frame(maxWidth: style == .full ? .infinity : nil)
            .frame(height: height)
            .padding(.horizontal, style == .full ? AppSpacing.spacing4 : AppSpacing.spacing6)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.full)
                    .fill(AppGradients.primary)
            )
            .shadowEmphasis()
            .opacity(isDisabled ? 0.4 : 1.0)
        }
        .buttonStyle(PressScaleButtonStyle())
        .disabled(isDisabled || isLoading)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: AppSpacing.spacing4) {
        PrimaryButton(title: "保存账单", icon: "checkmark", action: {})
        PrimaryButton(title: "记一笔", icon: "plus", size: .compact, action: {})
        PrimaryButton(title: "加载中", isLoading: true, action: {})
        PrimaryButton(title: "禁用状态", isDisabled: true, action: {})
        HStack {
            PrimaryButton(title: "确认", style: .fixed, size: .compact, action: {})
            PrimaryButton(title: "取消", style: .fixed, size: .compact, isDisabled: true, action: {})
        }
    }
    .padding(AppSpacing.spacing4)
    .background(AppColors.background)
    .preferredColorScheme(.light)
}
