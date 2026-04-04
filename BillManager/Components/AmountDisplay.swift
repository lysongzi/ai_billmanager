import SwiftUI

// MARK: - AmountType

enum AmountType {
    case income
    case expense
    case balance
    case neutral
}

// MARK: - AmountSize

enum AmountSize {
    case large   // 40pt Heavy
    case medium  // 22pt Semibold
    case small   // 16pt Semibold
    case micro   // 12pt Medium
}

// MARK: - AmountDisplay

struct AmountDisplay: View {
    let amount: Double
    var type: AmountType = .neutral
    var size: AmountSize = .small
    var showSign: Bool = false
    var currencyCode: String = "CNY"

    private var currencySymbol: String {
        currencyCode == "CNY" ? "¥" : "$"
    }

    private var color: Color {
        switch type {
        case .income:  return AppColors.income
        case .expense: return AppColors.expense
        case .balance: return AppColors.balance
        case .neutral: return AppColors.textPrimary
        }
    }

    private var font: Font {
        switch size {
        case .large:  return AppTypography.amountLarge
        case .medium: return AppTypography.amountMedium
        case .small:  return AppTypography.amountSmall
        case .micro:  return AppTypography.amountMicro
        }
    }

    private var signPrefix: String {
        guard showSign else { return "" }
        switch type {
        case .income:  return "+"
        case .expense: return "-"
        default:       return ""
        }
    }

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        let absAmount = abs(amount)
        let numStr = formatter.string(from: NSNumber(value: absAmount)) ?? "0.00"
        return "\(signPrefix)\(currencySymbol)\(numStr)"
    }

    var body: some View {
        Text(formattedAmount)
            .font(font)
            .monospacedDigit()
            .foregroundColor(color)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: AppSpacing.spacing4) {
        Group {
            Text("收入").font(AppTypography.caption).foregroundColor(AppColors.textTertiary)
            AmountDisplay(amount: 12345.67, type: .income, size: .large, showSign: true)
            AmountDisplay(amount: 12345.67, type: .income, size: .medium, showSign: true)
            AmountDisplay(amount: 12345.67, type: .income, size: .small, showSign: true)
            AmountDisplay(amount: 12345.67, type: .income, size: .micro)
        }

        Divider()

        Group {
            Text("支出").font(AppTypography.caption).foregroundColor(AppColors.textTertiary)
            AmountDisplay(amount: 888.00, type: .expense, size: .large)
            AmountDisplay(amount: 888.00, type: .expense, size: .medium, showSign: true)
            AmountDisplay(amount: 888.00, type: .expense, size: .small, showSign: true)
        }

        Divider()

        Group {
            Text("余额").font(AppTypography.caption).foregroundColor(AppColors.textTertiary)
            AmountDisplay(amount: 5000.00, type: .balance, size: .large)
        }

        Group {
            Text("中性").font(AppTypography.caption).foregroundColor(AppColors.textTertiary)
            AmountDisplay(amount: 9999.99, type: .neutral, size: .medium)
        }
    }
    .padding(AppSpacing.spacing4)
    .background(AppColors.background)
    .preferredColorScheme(.light)
}
