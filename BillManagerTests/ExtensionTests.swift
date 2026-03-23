import XCTest
@testable import BillManager

final class ExtensionTests: XCTestCase {
    
    func testCurrencyFormatted() {
        XCTAssertEqual(100.0.currencyFormatted, "¥100.00")
        XCTAssertEqual(1234.56.currencyFormatted, "¥1,234.56")
        XCTAssertEqual(0.0.currencyFormatted, "¥0.00")
    }
    
    func testCurrencyFormattedLargeAmount() {
        XCTAssertEqual(10000.0.currencyFormatted, "¥10,000.00")
        XCTAssertEqual(1000000.0.currencyFormatted, "¥1,000,000.00")
    }
    
    func testDateStartOfDay() {
        let date = Date()
        let startOfDay = date.startOfDay
        let calendar = Calendar.current
        
        XCTAssertEqual(calendar.component(.hour, from: startOfDay), 0)
        XCTAssertEqual(calendar.component(.minute, from: startOfDay), 0)
        XCTAssertEqual(calendar.component(.second, from: startOfDay), 0)
    }
    
    func testDateEndOfDay() {
        let date = Date()
        let endOfDay = date.endOfDay
        let calendar = Calendar.current
        
        XCTAssertEqual(calendar.component(.hour, from: endOfDay), 23)
        XCTAssertEqual(calendar.component(.minute, from: endOfDay), 59)
        XCTAssertEqual(calendar.component(.second, from: endOfDay), 59)
    }
    
    func testDateIsToday() {
        let today = Date()
        XCTAssertTrue(today.isToday)
        
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertFalse(yesterday.isToday)
    }
    
    func testDateIsYesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertTrue(yesterday.isYesterday)
        
        let today = Date()
        XCTAssertFalse(today.isYesterday)
    }
    
    func testDateIsThisWeek() {
        let today = Date()
        XCTAssertTrue(today.isThisWeek)
        
        let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        XCTAssertFalse(lastMonth.isThisWeek)
    }
    
    func testDateIsThisMonth() {
        let today = Date()
        XCTAssertTrue(today.isThisMonth)
        
        let lastYear = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
        XCTAssertFalse(lastYear.isThisMonth)
    }
    
    func testDateIsThisYear() {
        let today = Date()
        XCTAssertTrue(today.isThisYear)
        
        let lastYear = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
        XCTAssertFalse(lastYear.isThisYear)
    }
    
    func testDateRelativeDescription() {
        let today = Date()
        XCTAssertEqual(today.relativeDescription, "今天")
        
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertEqual(yesterday.relativeDescription, "昨天")
    }
    
    func testDateFormatted() {
        let date = Date()
        let formatted = date.formatted(as: "yyyy-MM-dd")
        
        XCTAssertTrue(formatted.contains("-"))
        XCTAssertTrue(formatted.count >= 8)
    }
    
    func testDateStartOfWeek() {
        let date = Date()
        let startOfWeek = date.startOfWeek
        let calendar = Calendar.current
        
        let weekday = calendar.component(.weekday, from: startOfWeek)
        XCTAssertEqual(weekday, 2)
    }
    
    func testDateStartOfMonth() {
        let date = Date()
        let startOfMonth = date.startOfMonth
        let calendar = Calendar.current
        
        let day = calendar.component(.day, from: startOfMonth)
        XCTAssertEqual(day, 1)
    }
    
    func testDateStartOfYear() {
        let date = Date()
        let startOfYear = date.startOfYear
        let calendar = Calendar.current
        
        let month = calendar.component(.month, from: startOfYear)
        XCTAssertEqual(month, 1)
    }
    
    func testColorHexInit() {
        let color = Color(hex: "#FF6B6B")
        XCTAssertNotNil(color)
        
        let color3 = Color(hex: "#F00")
        XCTAssertNotNil(color3)
        
        let colorInvalid = Color(hex: "invalid")
        XCTAssertNotNil(colorInvalid)
    }
    
    func testBillGroupedByDate() {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        let bills = [
            Bill(amount: 100, type: .expense, categoryName: "餐饮", date: today),
            Bill(amount: 50, type: .expense, categoryName: "交通", date: today),
            Bill(amount: 200, type: .income, categoryName: "工资", date: yesterday)
        ]
        
        let grouped = bills.groupedByDate()
        
        XCTAssertEqual(grouped.count, 2)
        
        let todayBills = grouped.first { calendar.isDate($0.date, inSameDayAs: today) }?.bills
        XCTAssertEqual(todayBills?.count, 2)
    }
    
    func testBillFilteredByTimeRange() {
        let bills = [
            Bill(amount: 100, type: .expense, categoryName: "餐饮", date: Date()),
            Bill(amount: 50, type: .expense, categoryName: "交通", date: Date())
        ]
        
        let filtered = bills.filtered(by: .month)
        XCTAssertEqual(filtered.count, 2)
    }
    
    func testBillTotalIncome() {
        let bills = [
            Bill(amount: 1000, type: .income, categoryName: "工资"),
            Bill(amount: 500, type: .income, categoryName: "奖金"),
            Bill(amount: 100, type: .expense, categoryName: "餐饮")
        ]
        
        XCTAssertEqual(bills.totalIncome(in: .month), 1500)
    }
    
    func testBillTotalExpense() {
        let bills = [
            Bill(amount: 1000, type: .income, categoryName: "工资"),
            Bill(amount: 100, type: .expense, categoryName: "餐饮"),
            Bill(amount: 50, type: .expense, categoryName: "交通")
        ]
        
        XCTAssertEqual(bills.totalExpense(in: .month), 150)
    }
}