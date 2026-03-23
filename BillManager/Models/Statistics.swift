import Foundation

struct Statistics {
    var totalIncome: Double
    var totalExpense: Double
    var balance: Double
    var categoryBreakdown: [CategoryStat]
    var dailyTrend: [DailyStat]

    init(
        totalIncome: Double = 0,
        totalExpense: Double = 0,
        categoryBreakdown: [CategoryStat] = [],
        dailyTrend: [DailyStat] = []
    ) {
        self.totalIncome = totalIncome
        self.totalExpense = totalExpense
        self.balance = totalIncome - totalExpense
        self.categoryBreakdown = categoryBreakdown
        self.dailyTrend = dailyTrend
    }
}

struct CategoryStat: Identifiable {
    var id: UUID
    var categoryName: String
    var icon: String
    var colorHex: String
    var amount: Double
    var percentage: Double
    var type: BillType

    init(
        id: UUID = UUID(),
        categoryName: String,
        icon: String,
        colorHex: String,
        amount: Double,
        percentage: Double,
        type: BillType
    ) {
        self.id = id
        self.categoryName = categoryName
        self.icon = icon
        self.colorHex = colorHex
        self.amount = amount
        self.percentage = percentage
        self.type = type
    }
}

struct DailyStat: Identifiable {
    var id: Date
    var date: Date
    var income: Double
    var expense: Double

    init(id: Date = Date(), date: Date, income: Double = 0, expense: Double = 0) {
        self.id = date
        self.date = date
        self.income = income
        self.expense = expense
    }

    var amount: Double {
        income + expense
    }
}

enum TimeRange: String, CaseIterable, Identifiable {
    case week = "week"
    case month = "month"
    case year = "year"
    case custom = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .week: return "本周"
        case .month: return "本月"
        case .year: return "本年"
        case .custom: return "自定义"
        }
    }

    var icon: String {
        switch self {
        case .week: return "calendar"
        case .month: return "calendar.badge.month"
        case .year: return "calendar.badge.clock"
        case .custom: return "calendar.badge.exclamationmark"
        }
    }

    func dateRange() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .week:
            let start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let end = calendar.date(byAdding: .day, value: 6, to: start)!
            return (start, end)
        case .month:
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start)!
            return (start, end)
        case .year:
            let start = calendar.date(from: calendar.dateComponents([.year], from: now))!
            let end = calendar.date(byAdding: DateComponents(month: 11, day: 31), to: start)!
            return (start, end)
        case .custom:
            return (now, now)
        }
    }
}