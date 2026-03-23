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
}