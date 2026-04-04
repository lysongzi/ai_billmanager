import XCTest
import SwiftData
@testable import BillManager

@MainActor
final class ViewModelTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var ledgerService: LedgerService!
    var billService: BillService!
    var statisticsService: StatisticsService!
    var testLedger: Ledger!

    override func setUpWithError() throws {
        container = try ModelContainer(
            for: Ledger.self, Bill.self, Category.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = container.mainContext

        let ledgerRepo = LedgerRepository(modelContext: context)
        let categoryRepo = CategoryRepository(modelContext: context)
        let billRepo = BillRepository(modelContext: context)

        ledgerService = LedgerService(ledgerRepository: ledgerRepo, categoryRepository: categoryRepo)
        billService = BillService(billRepository: billRepo)
        statisticsService = StatisticsService()

        // Create test ledger with default categories
        testLedger = try ledgerService.createLedgerWithDefaults(
            name: "测试账本",
            icon: "book.fill",
            colorHex: "#007AFF"
        )
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
        ledgerService = nil
        billService = nil
        statisticsService = nil
        testLedger = nil
    }

    // MARK: - BillListViewModel Tests

    func testBillListViewModelLoadBills() async throws {
        // Create test bills
        try billService.createBill(
            amount: 100, type: .expense, categoryName: "餐饮",
            categoryIcon: "fork.knife", categoryColorHex: "#FF6B6B",
            note: nil, date: Date(), ledger: testLedger
        )
        try billService.createBill(
            amount: 500, type: .income, categoryName: "工资",
            categoryIcon: "dollarsign.circle.fill", categoryColorHex: "#2ECC71",
            note: nil, date: Date(), ledger: testLedger
        )

        let vm = BillListViewModel(billService: billService)
        vm.selectedLedger = testLedger
        await vm.loadBills()

        XCTAssertEqual(vm.bills.count, 2)
        XCTAssertNil(vm.errorMessage)
    }

    func testBillListViewModelTotals() async throws {
        try billService.createBill(
            amount: 1000, type: .income, categoryName: "工资",
            categoryIcon: "dollarsign.circle.fill", categoryColorHex: "#2ECC71",
            note: nil, date: Date(), ledger: testLedger
        )
        try billService.createBill(
            amount: 300, type: .expense, categoryName: "餐饮",
            categoryIcon: "fork.knife", categoryColorHex: "#FF6B6B",
            note: nil, date: Date(), ledger: testLedger
        )

        let vm = BillListViewModel(billService: billService)
        vm.selectedLedger = testLedger
        await vm.loadBills()

        XCTAssertEqual(vm.totalIncome, 1000)
        XCTAssertEqual(vm.totalExpense, 300)
        XCTAssertEqual(vm.balance, 700)
    }

    func testBillListViewModelDeleteBill() async throws {
        let bill = try billService.createBill(
            amount: 100, type: .expense, categoryName: "餐饮",
            categoryIcon: "fork.knife", categoryColorHex: "#FF6B6B",
            note: nil, date: Date(), ledger: testLedger
        )

        let vm = BillListViewModel(billService: billService)
        vm.selectedLedger = testLedger
        await vm.loadBills()
        XCTAssertEqual(vm.bills.count, 1)

        await vm.deleteBill(bill)
        XCTAssertEqual(vm.bills.count, 0)
    }

    func testBillListViewModelFilterByType() async throws {
        try billService.createBill(
            amount: 100, type: .expense, categoryName: "餐饮",
            categoryIcon: "fork.knife", categoryColorHex: "#FF6B6B",
            note: nil, date: Date(), ledger: testLedger
        )
        try billService.createBill(
            amount: 500, type: .income, categoryName: "工资",
            categoryIcon: "dollarsign.circle.fill", categoryColorHex: "#2ECC71",
            note: nil, date: Date(), ledger: testLedger
        )

        let vm = BillListViewModel(billService: billService)
        vm.selectedLedger = testLedger
        await vm.filterByType(.expense)

        XCTAssertEqual(vm.bills.count, 1)
        XCTAssertEqual(vm.bills[0].type, .expense)
    }

    // MARK: - StatisticsViewModel Tests

    func testStatisticsViewModelLoadStatistics() async throws {
        try billService.createBill(
            amount: 1000, type: .income, categoryName: "工资",
            categoryIcon: "dollarsign.circle.fill", categoryColorHex: "#2ECC71",
            note: nil, date: Date(), ledger: testLedger
        )
        try billService.createBill(
            amount: 300, type: .expense, categoryName: "餐饮",
            categoryIcon: "fork.knife", categoryColorHex: "#FF6B6B",
            note: nil, date: Date(), ledger: testLedger
        )

        let vm = StatisticsViewModel(billService: billService, statisticsService: statisticsService)
        await vm.loadStatistics(for: testLedger, range: .month)

        XCTAssertNotNil(vm.statistics)
        XCTAssertNil(vm.errorMessage)
        XCTAssertFalse(vm.isLoading)
    }

    func testStatisticsViewModelSelectedBillTypeFilter() async throws {
        try billService.createBill(
            amount: 1000, type: .income, categoryName: "工资",
            categoryIcon: "dollarsign.circle.fill", categoryColorHex: "#2ECC71",
            note: nil, date: Date(), ledger: testLedger
        )
        try billService.createBill(
            amount: 300, type: .expense, categoryName: "餐饮",
            categoryIcon: "fork.knife", categoryColorHex: "#FF6B6B",
            note: nil, date: Date(), ledger: testLedger
        )

        let vm = StatisticsViewModel(billService: billService, statisticsService: statisticsService)
        await vm.loadStatistics(for: testLedger, range: .month)

        vm.selectedBillType = .income
        XCTAssertEqual(vm.totalAmount, 1000)

        vm.selectedBillType = .expense
        XCTAssertEqual(vm.totalAmount, 300)
    }

    // MARK: - LedgerListViewModel Tests

    func testLedgerListViewModelLoadLedgers() async throws {
        let vm = LedgerListViewModel(ledgerService: ledgerService)
        await vm.loadLedgers()

        // testLedger was created in setUp
        XCTAssertGreaterThanOrEqual(vm.ledgers.count, 1)
        XCTAssertNil(vm.errorMessage)
    }

    func testLedgerListViewModelCreateLedger() async throws {
        let vm = LedgerListViewModel(ledgerService: ledgerService)
        await vm.loadLedgers()
        let initialCount = vm.ledgers.count

        await vm.createLedger(name: "新账本", icon: "star.fill", colorHex: "#FF6B6B")

        XCTAssertEqual(vm.ledgers.count, initialCount + 1)
        XCTAssertNil(vm.errorMessage)
    }

    func testLedgerListViewModelDeleteLedger() async throws {
        let vm = LedgerListViewModel(ledgerService: ledgerService)
        await vm.loadLedgers()
        let initialCount = vm.ledgers.count

        await vm.deleteLedger(testLedger)

        XCTAssertEqual(vm.ledgers.count, initialCount - 1)
    }

    func testLedgerListViewModelArchiveLedger() async throws {
        let vm = LedgerListViewModel(ledgerService: ledgerService)
        await vm.loadLedgers()

        await vm.archiveLedger(testLedger)

        XCTAssertTrue(vm.archivedLedgers.contains { $0.id == testLedger.id })
        XCTAssertFalse(vm.activeLedgers.contains { $0.id == testLedger.id })
    }

    // MARK: - AddRecordViewModel Tests

    func testAddRecordViewModelSave() async throws {
        let categoryRepo = CategoryRepository(modelContext: context)
        let vm = AddRecordViewModel(billService: billService, categoryRepository: categoryRepo)

        await vm.loadCategories(for: testLedger)
        XCTAssertFalse(vm.categories.isEmpty)

        vm.amount = "100"
        vm.selectedType = .expense
        vm.selectedCategory = vm.categories.first

        await vm.save(to: testLedger)

        XCTAssertTrue(vm.isSaved)
        XCTAssertNil(vm.errorMessage)
    }

    func testAddRecordViewModelInvalidAmount() async throws {
        let categoryRepo = CategoryRepository(modelContext: context)
        let vm = AddRecordViewModel(billService: billService, categoryRepository: categoryRepo)

        vm.amount = "0"
        vm.selectedType = .expense
        XCTAssertFalse(vm.canSave)

        vm.amount = "-100"
        XCTAssertFalse(vm.canSave)

        vm.amount = "abc"
        XCTAssertFalse(vm.canSave)
    }
}
