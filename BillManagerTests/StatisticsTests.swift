import XCTest
@testable import BillManager

final class StatisticsTests: XCTestCase {
    
    func testTimeRangeWeek() {
        let (start, end) = TimeRange.week.dateRange()
        let calendar = Calendar.current
        
        let daysDiff = calendar.dateComponents([.day], from: start, to: end).day
        XCTAssertEqual(daysDiff, 6)
        
        XCTAssertTrue(start <= end)
    }
    
    func testTimeRangeMonth() {
        let (start, end) = TimeRange.month.dateRange()
        let calendar = Calendar.current
        
        let day = calendar.component(.day, from: start)
        XCTAssertEqual(day, 1)
        
        let range = calendar.range(of: .day, in: .month, for: start)!
        XCTAssertEqual(calendar.component(.day, from: end), range.count)
    }
    
    func testTimeRangeYear() {
        let (start, end) = TimeRange.year.dateRange()
        let calendar = Calendar.current
        
        let month = calendar.component(.month, from: start)
        XCTAssertEqual(month, 1)
        
        XCTAssertTrue(start <= end)
        
        let day = calendar.component(.day, from: start)
        XCTAssertEqual(day, 1)
    }
    
    func testTimeRangeDisplayName() {
        XCTAssertEqual(TimeRange.week.displayName, "本周")
        XCTAssertEqual(TimeRange.month.displayName, "本月")
        XCTAssertEqual(TimeRange.year.displayName, "本年")
        XCTAssertEqual(TimeRange.custom.displayName, "自定义")
    }
    
    func testTimeRangeIcon() {
        XCTAssertEqual(TimeRange.week.icon, "calendar")
        XCTAssertEqual(TimeRange.month.icon, "calendar.badge.month")
        XCTAssertEqual(TimeRange.year.icon, "calendar.badge.clock")
        XCTAssertEqual(TimeRange.custom.icon, "calendar.badge.exclamationmark")
    }
    
    func testBillTypeDisplayName() {
        XCTAssertEqual(BillType.income.displayName, "收入")
        XCTAssertEqual(BillType.expense.displayName, "支出")
    }
    
    func testBillTypeIcon() {
        XCTAssertEqual(BillType.income.icon, "arrow.down.circle.fill")
        XCTAssertEqual(BillType.expense.icon, "arrow.up.circle.fill")
    }
    
    func testCategoryStatInitialization() {
        let stat = CategoryStat(
            categoryName: "餐饮",
            icon: "fork.knife",
            colorHex: "#FF6B6B",
            amount: 100,
            percentage: 50,
            type: .expense
        )
        
        XCTAssertEqual(stat.categoryName, "餐饮")
        XCTAssertEqual(stat.amount, 100)
        XCTAssertEqual(stat.percentage, 50)
        XCTAssertEqual(stat.type, .expense)
    }
    
    func testDailyStatInitialization() {
        let stat = DailyStat(date: Date(), income: 100, expense: 50)
        
        XCTAssertEqual(stat.income, 100)
        XCTAssertEqual(stat.expense, 50)
        XCTAssertEqual(stat.amount, 150)
    }
    
    func testStatisticsInitialization() {
        let stats = Statistics(
            totalIncome: 1000,
            totalExpense: 500,
            categoryBreakdown: [],
            dailyTrend: []
        )

        XCTAssertEqual(stats.totalIncome, 1000)
        XCTAssertEqual(stats.totalExpense, 500)
        XCTAssertEqual(stats.balance, 500)
    }

    // MARK: - TimeRange.year Bug 回归测试

    /// 回归测试：修复 TimeRange.year 年末日期计算错误
    /// 原 Bug：使用 DateComponents(month: 11, day: 31) 在 12月31日 时会计算出 2月1日（跨年）
    func testTimeRangeYearEndDateIsDecember31() {
        let (start, end) = TimeRange.year.dateRange()
        let calendar = Calendar.current

        // start 应该是 1月1日
        XCTAssertEqual(calendar.component(.month, from: start), 1)
        XCTAssertEqual(calendar.component(.day, from: start), 1)

        // end 应该是 12月31日
        XCTAssertEqual(calendar.component(.month, from: end), 12)
        XCTAssertEqual(calendar.component(.day, from: end), 31)

        // end 的年份应该和 start 一致（不跨年）
        XCTAssertEqual(calendar.component(.year, from: start), calendar.component(.year, from: end))
    }

    /// 验证 year 范围 start <= end 且相差约 365 天
    func testTimeRangeYearSpan() {
        let (start, end) = TimeRange.year.dateRange()
        let calendar = Calendar.current

        XCTAssertTrue(start <= end)

        let days = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        // 闰年364，平年364（0-indexed，12月31日 - 1月1日 = 364天）
        XCTAssertTrue(days == 364 || days == 365, "year range should span ~365 days, got \(days)")
    }

    // MARK: - StatisticsService Tests

    func testStatisticsServiceCalculateStatistics() {
        let service = StatisticsService()

        let bills = [
            Bill(amount: 1000, type: .income, categoryName: "工资"),
            Bill(amount: 500, type: .expense, categoryName: "餐饮"),
            Bill(amount: 200, type: .expense, categoryName: "交通")
        ]

        let stats = service.calculateStatistics(bills: bills)

        XCTAssertEqual(stats.totalIncome, 1000)
        XCTAssertEqual(stats.totalExpense, 700)
        XCTAssertEqual(stats.balance, 300)
    }

    func testStatisticsServiceCalculateCategoryStats() {
        let service = StatisticsService()

        let bills = [
            Bill(amount: 300, type: .expense, categoryName: "餐饮", categoryIcon: "fork.knife", categoryColorHex: "#FF6B6B"),
            Bill(amount: 200, type: .expense, categoryName: "餐饮", categoryIcon: "fork.knife", categoryColorHex: "#FF6B6B"),
            Bill(amount: 100, type: .expense, categoryName: "交通", categoryIcon: "car.fill", categoryColorHex: "#4ECDC4")
        ]

        let categoryStats = service.calculateCategoryStats(bills: bills)

        XCTAssertEqual(categoryStats.count, 2)
        XCTAssertEqual(categoryStats[0].categoryName, "餐饮")
        XCTAssertEqual(categoryStats[0].amount, 500)
        XCTAssertEqual(categoryStats[1].categoryName, "交通")
        XCTAssertEqual(categoryStats[1].amount, 100)

        let totalAmount = 600.0
        XCTAssertEqual(categoryStats[0].percentage, (500 / totalAmount) * 100, accuracy: 0.01)
    }

    func testStatisticsServiceEmptyBills() {
        let service = StatisticsService()
        let stats = service.calculateStatistics(bills: [])

        XCTAssertEqual(stats.totalIncome, 0)
        XCTAssertEqual(stats.totalExpense, 0)
        XCTAssertEqual(stats.balance, 0)
        XCTAssertTrue(stats.categoryBreakdown.isEmpty)
    }
}