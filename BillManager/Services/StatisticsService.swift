import Foundation

// MARK: - StatisticsService

final class StatisticsService {

    // MARK: - Calculate Statistics

    func calculateStatistics(bills: [Bill]) -> Statistics {
        let income = bills.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let expense = bills.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        let categoryStats = calculateCategoryStats(bills: bills)
        return Statistics(
            totalIncome: income,
            totalExpense: expense,
            categoryBreakdown: categoryStats,
            dailyTrend: []
        )
    }

    // MARK: - Calculate Category Stats

    func calculateCategoryStats(bills: [Bill]) -> [CategoryStat] {
        guard !bills.isEmpty else { return [] }

        let totalAmount = bills.reduce(0) { $0 + $1.amount }
        let grouped = Dictionary(grouping: bills) { $0.categoryName }

        return grouped.compactMap { (categoryName, categoryBills) -> CategoryStat? in
            guard let firstBill = categoryBills.first else { return nil }
            let total = categoryBills.reduce(0) { $0 + $1.amount }
            let percentage = totalAmount > 0 ? (total / totalAmount) * 100 : 0
            return CategoryStat(
                categoryName: categoryName,
                icon: firstBill.categoryIcon,
                colorHex: firstBill.categoryColorHex,
                amount: total,
                percentage: percentage,
                type: firstBill.type
            )
        }
        .sorted { $0.amount > $1.amount }
    }

    // MARK: - Calculate Daily Stats

    func calculateDailyStats(bills: [Bill], in range: TimeRange) -> [DailyStat] {
        // 使用修复后的 dateRange()
        let (startDate, endDate) = range.dateRange()
        var stats: [DailyStat] = []

        var currentDate = Calendar.current.startOfDay(for: startDate)
        let endDayStart = Calendar.current.startOfDay(for: endDate)

        while currentDate <= endDayStart {
            let dayBills = bills.filter { bill in
                Calendar.current.isDate(bill.date, inSameDayAs: currentDate)
            }

            let income = dayBills.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let expense = dayBills.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }

            stats.append(DailyStat(date: currentDate, income: income, expense: expense))

            guard let next = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = next
        }

        return stats
    }
}
