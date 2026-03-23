import XCTest
@testable import BillManager

final class ModelTests: XCTestCase {
    
    func testLedgerInitialization() {
        let ledger = Ledger(name: "测试账本", icon: "book.fill", colorHex: "#007AFF")
        
        XCTAssertEqual(ledger.name, "测试账本")
        XCTAssertEqual(ledger.icon, "book.fill")
        XCTAssertEqual(ledger.colorHex, "#007AFF")
        XCTAssertFalse(ledger.isArchived)
        XCTAssertNotNil(ledger.id)
        XCTAssertNotNil(ledger.createdAt)
    }
    
    func testLedgerDefaultValues() {
        let ledger = Ledger(name: "默认账本")
        
        XCTAssertEqual(ledger.icon, "book.fill")
        XCTAssertEqual(ledger.colorHex, "#007AFF")
        XCTAssertFalse(ledger.isArchived)
        XCTAssertNotNil(ledger.bills)
        XCTAssertNotNil(ledger.categories)
    }
    
    func testLedgerTotalIncome() {
        let ledger = Ledger(name: "测试")
        ledger.bills = [
            Bill(amount: 100, type: .income, categoryName: "工资"),
            Bill(amount: 50, type: .expense, categoryName: "餐饮"),
            Bill(amount: 200, type: .income, categoryName: "奖金")
        ]
        
        XCTAssertEqual(ledger.totalIncome, 300)
    }
    
    func testLedgerTotalExpense() {
        let ledger = Ledger(name: "测试")
        ledger.bills = [
            Bill(amount: 100, type: .income, categoryName: "工资"),
            Bill(amount: 50, type: .expense, categoryName: "餐饮"),
            Bill(amount: 30, type: .expense, categoryName: "交通")
        ]
        
        XCTAssertEqual(ledger.totalExpense, 80)
    }
    
    func testLedgerBalance() {
        let ledger = Ledger(name: "测试")
        ledger.bills = [
            Bill(amount: 1000, type: .income, categoryName: "工资"),
            Bill(amount: 300, type: .expense, categoryName: "餐饮"),
            Bill(amount: 100, type: .expense, categoryName: "交通")
        ]
        
        XCTAssertEqual(ledger.balance, 600)
    }
    
    func testLedgerBalanceNegative() {
        let ledger = Ledger(name: "测试")
        ledger.bills = [
            Bill(amount: 100, type: .income, categoryName: "工资"),
            Bill(amount: 300, type: .expense, categoryName: "餐饮")
        ]
        
        XCTAssertEqual(ledger.balance, -200)
    }
    
    func testBillInitialization() {
        let bill = Bill(
            amount: 100.50,
            type: .expense,
            categoryName: "餐饮",
            categoryIcon: "fork.knife",
            categoryColorHex: "#FF6B6B"
        )
        
        XCTAssertEqual(bill.amount, 100.50)
        XCTAssertEqual(bill.type, .expense)
        XCTAssertEqual(bill.categoryName, "餐饮")
        XCTAssertEqual(bill.categoryIcon, "fork.knife")
        XCTAssertEqual(bill.categoryColorHex, "#FF6B6B")
        XCTAssertNotNil(bill.id)
        XCTAssertNotNil(bill.date)
        XCTAssertNotNil(bill.createdAt)
        XCTAssertNotNil(bill.updatedAt)
    }
    
    func testBillTypeConversion() {
        let bill = Bill(amount: 100, type: .income, categoryName: "工资")
        
        XCTAssertEqual(bill.typeRawValue, "income")
        
        bill.type = .expense
        XCTAssertEqual(bill.typeRawValue, "expense")
        XCTAssertEqual(bill.type, .expense)
    }
    
    func testBillNote() {
        let bill = Bill(amount: 100, type: .expense, categoryName: "餐饮", note: "午餐")
        
        XCTAssertEqual(bill.note, "午餐")
        
        let billWithoutNote = Bill(amount: 100, type: .expense, categoryName: "餐饮")
        XCTAssertNil(billWithoutNote.note)
    }
    
    func testCategoryInitialization() {
        let category = Category(
            name: "餐饮",
            icon: "fork.knife",
            colorHex: "#FF6B6B",
            type: .expense
        )
        
        XCTAssertEqual(category.name, "餐饮")
        XCTAssertEqual(category.icon, "fork.knife")
        XCTAssertEqual(category.colorHex, "#FF6B6B")
        XCTAssertEqual(category.type, .expense)
    }
    
    func testCategoryTypeConversion() {
        let category = Category(name: "工资", icon: "banknote.fill", type: .income)
        
        XCTAssertEqual(category.typeRawValue, "income")
        
        category.type = .expense
        XCTAssertEqual(category.typeRawValue, "expense")
    }
}