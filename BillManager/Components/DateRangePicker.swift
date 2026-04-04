import SwiftUI

// MARK: - DateRangeOption

enum DateRangeOption: String, CaseIterable {
    case week  = "周"
    case month = "月"
    case year  = "年"
}

// MARK: - DateRangePicker

struct DateRangePicker: View {
    @Binding var selected: DateRangeOption
    @Namespace private var slideNamespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(DateRangeOption.allCases, id: \.self) { option in
                ZStack {
                    if selected == option {
                        RoundedRectangle(cornerRadius: AppCornerRadius.full)
                            .fill(AppColors.cardBackground)
                            .shadowLight()
                            .matchedGeometryEffect(id: "slider", in: slideNamespace)
                    }

                    Text(option.rawValue)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(
                            selected == option
                                ? AppColors.textPrimary
                                : AppColors.textSecondary
                        )
                }
                .frame(maxWidth: .infinity)
                .frame(height: 30)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        selected = option
                    }
                }
            }
        }
        .padding(3)
        .frame(height: 36)
        .background(
            Capsule()
                .fill(AppColors.backgroundAlt)
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: AppSpacing.spacing6) {
        DateRangePicker(selected: .constant(.month))

        StatefulPreviewWrapper(DateRangeOption.month) { binding in
            VStack(spacing: AppSpacing.spacing3) {
                DateRangePicker(selected: binding)
                Text("当前选择：\(binding.wrappedValue.rawValue)视图")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
        }
    }
    .padding(AppSpacing.spacing4)
    .background(AppColors.background)
    .preferredColorScheme(.light)
}

// MARK: - StatefulPreviewWrapper Helper

private struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State private var value: Value
    private let content: (Binding<Value>) -> Content

    init(_ initialValue: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: initialValue)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}
