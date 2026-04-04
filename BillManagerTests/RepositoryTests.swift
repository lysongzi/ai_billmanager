import XCTest
import SwiftData
@testable import BillManager

@MainActor
final class RepositoryTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var ledgerRepo: LedgerRepository!
    var billRepo: BillRepository!
    var categoryRepo: CategoryRepository!

    override func setUpWithError() throws {
        container = try ModelContainer(
            for: Ledger.self, Bill.self, Category.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = container.mainContext
        ledgerRepo = LedgerRepository(modelContext: context)
        billRepo = BillRepository(modelContext: context)
        categoryRepo = CategoryRepository(modelContext: context)
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
        ledgerRepo = nil
        billRepo = nil
        categoryRepo = nil
    }

    // MARK: - LedgerRepository Tests

    func testCreateLedger() throws {
        let ledger = try ledgerRepo.createLedger(name: "测试账本", icon: "book.fill", colorHex: "#007AFF")

        XCTAssertEqual(ledger.name, "测试账本")
        XCTAssertEqual(ledger.icon, "book.fill")
        XCTAssertEqual(ledger.colorHex, "#007AFF")
        XCTAssertFalse(ledger.isArchived)
    }

    func testFetchAllLedgers() throws {
        try ledgerRepo.createLedger(name: "账本1", icon: "book.fill", colorHex: "#007AFF")
        try ledgerRepo.createLedger(name: "账本2", icon: "folder.fill", colorHex: "#FF6B6B")

        let ledgers = try ledgerRepo.fetchAllLedgers()
        XCTAssertEqual(ledgers.count, 2)
    }

    func testFetchActiveLedgers() throws {
        let active = try ledgerRepo.createLedger(name: "活跃账本", icon: "book.fill", colorHex: "#007AFF")
        let archived = try ledgerRepo.createLedger(name: "归档账本", icon: "folder.fill", colorHex: "#FF6B6B")
        try ledgerRepo.archiveLedger(archived, archived: true)

        let activeLedgers = try ledgerRepo.fetchActiveLedgers()
        XCTAssertEqual(activeLedgers.count, 1)
        XCTAssertEqual(activeLedgers[0].id, active.id)
    }

    func testUpdateLedger() throws {
        let ledger = try ledgerRepo.createLedger(name: "旧名字", icon: "book.fill", colorHex: "#007AFF")

        try ledgerRepo.updateLedger(ledger, name: "新名字", icon: "star.fill", colorHex: "#FF6B6B")

        XCTAssertEqual(ledger.name, "新名字")
        XCTAssertEqual(ledger.icon, "star.fill")
        XCTAssertEqual(ledger.colorHex, "#FF6B6B")
    }

    func testDeleteLedger() throws {
        let ledger = try ledgerRepo.createLedger(name: "要删除的账本", icon: "book.fill", colorHex: "#007AFF")

        try ledgerRepo.deleteLedger(ledger)

        let ledgers = try ledgerRepo.fetchAllLedgers()
        XCTAssertEqual(ledgers.count, 0)
    }

    func testArchiveLedger() throws {
        let ledger = try ledgerRepo.createLedger(name: "测试账本", icon: "book.fill", colorHex: "#007AFF")
        XCTAssertFalse(ledger.isArchived)

        try ledgerRepo.archiveLedger(ledger, archived: true)
        XCTAssertTrue(ledger.isArchived)

        try ledgerRepo.archiveLedger(ledger, archived: false)
        XCTAssertFalse(ledger.isArchived)
    }

    // MARK: - BillRepository Tests

    func testCreateBill() throws {
        let ledger = try ledgerRepo.createLedger(name: "测试账本", icon: "book.fill", colorHex: "#007AFF")

        let bill = try billRepo.createBill(
            amount: 100,
            type: .expense,
            categoryName: "餐饮",
            categoryIcon: "fork.knife",
            categoryColorHex: "#FF6B6B",
            note: "午餐",
            date: Date(),
            ledger: ledger
        )

        XCTAssertEqual(bill.amount, 100)
        XCTAssertEqual(bill.type, .expense)
        XCTAssertEqual(bill.categoryName, "餐饮")
        XCTAssertEqual(bill.note, "午餐")
    }

    func testFetchBillsForLedger() throws {
        let ledger1 = try ledgerRepo.createLedger(name: "账本1", icon: "book.fill", colorHex: "#007AFF")
        let ledger2 = try ledgerRepo.createLedger(name: "账本2", icon: "folder.fill", colorHex: "#FF6B6B")

        try billRepo.createBill(amount: 100, type: .expense, categoryName: "餐饮",
                                categoryIcon: "fork.knife", categoryColorHex: "#FF6B6B",
                                note: nil, date: Date(), ledger: ledger1)
        try billRepo.createBill(amount: 200, type: .income, categoryName: "工资",
                                categoryIcon: "dollarsign.circle.fill", categoryColorHex: "#2ECC71",
                                note: nil, date: Date(), ledger: ledger2)

        let bills1 = try billRepo.fetchBills(for: ledger1)
        let bills2 = try billRepo.fetchBills(for: ledger2)

        XCTAssertEqual(bills1.count, 1)
        XCTAssertEqual(bills2.count, 1)
        XCTAssertEqual(bills1[0].amount, 100)
        XCTAssertEqual(bills2[0].amount, 200)
    }

    func testDeleteBill() throws {
        let ledger = try ledgerRepo.createLedger(name: "测试账本", icon: "book.fill", colorHex: "#007AFF")
        let bill = try billRepo.createBill(
            amount: 100, type: .expense, categoryName: "餐饮",
            categoryIcon: "fork.knife", categoryColorHex: "#FF6B6B",
            note: nil, date: Date(), ledger: ledger
        )

        try billRepo.deleteBill(bill)

        let bills = try billRepo.fetchBills(for: ledger)
        XCTAssertEqual(bills.count, 0)
    }

    func testUpdateBill() throws {
        let ledger = try ledgerRepo.createLedger(name: "测试账本", icon: "book.fill", colorHex: "#007AFF")
        let bill = try billRepo.createBill(
            amount: 100, type: .expense, categoryName: "餐饮",
            categoryIcon: "fork.knife", categoryColorHex: "#FF6B6B",
            note: nil, date: Date(), ledger: ledger
        )

        try billRepo.updateBill(bill, amount: 200, categoryName: "交通")

        XCTAssertEqual(bill.amount, 200)
        XCTAssertEqual(bill.categoryName, "交通")
    }

    // MARK: - CategoryRepository Tests

    func testCreateDefaultCategories() throws {
        let ledger = try ledgerRepo.createLedger(name: "测试账本", icon: "book.fill", colorHex: "#007AFF")

        try categoryRepo.createDefaultCategories(for: ledger)

        let expenseCategories = try categoryRepo.fetchCategories(for: ledger, type: .expense)
        let incomeCategories = try categoryRepo.fetchCategories(for: ledger, type: .income)

        XCTAssertEqual(expenseCategories.count, 8)
        XCTAssertEqual(incomeCategories.count, 4)
    }

    func testCreateCategory() throws {
        let ledger = try ledgerRepo.createLedger(name: "测试账本", icon: "book.fill", colorHex: "#007AFF")

        let category = try categoryRepo.createCategory(
            name: "测试分类",
            icon: "star.fill",
            colorHex: "#FF6B6B",
            type: .expense,
            ledger: ledger
        )

        XCTAssertEqual(category.name, "测试分类")
        XCTAssertEqual(category.type, .expense)
    }

    func testDeleteCategory() throws {
        let ledger = try ledgerRepo.createLedger(name: "测试账本", icon: "book.fill", colorHex: "#007AFF")
        let category = try categoryRepo.createCategory(
            name: "测试分类", icon: "star.fill", colorHex: "#FF6B6B",
            type: .expense, ledger: ledger
        )

        try categoryRepo.deleteCategory(category)

        let categories = try categoryRepo.fetchCategories(for: ledger, type: .expense)
        XCTAssertEqual(categories.count, 0)
    }
}
