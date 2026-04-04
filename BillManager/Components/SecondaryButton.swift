import SwiftUI

// MARK: - SecondaryButton

enum SecondaryButtonVariant {
    case outlined  // 透明背景 + 描边
    case filled    // primarySurface 背景
}

struct SecondaryButton: View {
    let title: String
    var icon: String? = nil
    var variant: SecondaryButtonVariant = .outlined
    var style: PrimaryButtonStyle = .full
    var size: PrimaryButtonSize = .standard
    var isDisabled: Bool = false
    let action: () -> Void

    @State private var isPressed = false

    private var height: CGFloat {
        switch size {
        case .standard: return 52
        case .compact:  return 44
        }
    }

    private var background: Color {
        switch variant {
        case .outlined: return .clear
        case .filled:   return AppColors.primarySurface
        }
    }

    var body: some View {
        Button {
            guard !isDisabled else { return }
            action()
        } label: {
            HStack(spacing: AppSpacing.spacing2) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                }
                Text(title)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(AppColors.primary)
            .frame(maxWidth: style == .full ? .infinity : nil)
            .frame(height: height)
            .padding(.horizontal, style == .full ? AppSpacing.spacing4 : AppSpacing.spacing6)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.full)
                    .fill(isPressed ? AppColors.primaryLight.opacity(0.3) : background)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppCornerRadius.full)
                            .strokeBorder(
                                variant == .outlined ? AppColors.primary : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
            .opacity(isDisabled ? 0.4 : 1.0)
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        ._onButtonGesture(pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: AppSpacing.spacing4) {
        SecondaryButton(title: "取消", action: {})
        SecondaryButton(title: "返回", icon: "chevron.left", action: {})
        SecondaryButton(title: "编辑", variant: .filled, action: {})
        SecondaryButton(title: "禁用", isDisabled: true, action: {})
        HStack {
            PrimaryButton(title: "保存", style: .fixed, size: .compact, action: {})
            SecondaryButton(title: "取消", style: .fixed, size: .compact, action: {})
        }
    }
    .padding(AppSpacing.spacing4)
    .background(AppColors.background)
    .preferredColorScheme(.light)
}
