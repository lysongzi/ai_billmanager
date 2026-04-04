import Foundation
import Observation

// MARK: - BillListViewModel

@Observable
@MainActor
final class BillListViewModel {
    var bills: [Bill] = []
    var groupedBills: [(date: Date, bills: [Bill])] = []
    var selectedLedger: Ledger?
    var searchKeyword: String = "" {
        didSet { Task { await searchBills(keyword: searchKeyword) } }
    }
    var selectedType: BillType? = nil
    var isLoading: Bool = false
    var errorMessage: String? = nil

    // Summary computed from bills
    var totalIncome: Double { bills.filter { $0.type == .income }.reduce(0) { $0 + $1.amount } }
    var totalExpense: Double { bills.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount } }
    var balance: Double { totalIncome - totalExpense }

    private let billService: BillService

    init(billService: BillService) {
        self.billService = billService
    }

    // MARK: - Load Bills

    func loadBills() async {
        guard let ledger = selectedLedger else {
            bills = []
            groupedBills = []
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let fetched = try billService.fetchBills(for: ledger, type: selectedType, keyword: searchKeyword.isEmpty ? nil : searchKeyword)
            bills = fetched.sorted { $0.date > $1.date }
            groupedBills = bills.groupedByDate()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Delete Bill

    func deleteBill(_ bill: Bill) async {
        do {
            try billService.deleteBill(bill)
            await loadBills()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Search Bills

    func searchBills(keyword: String) async {
        guard let ledger = selectedLedger else { return }
        do {
            let fetched = try billService.fetchBills(for: ledger, type: selectedType, keyword: keyword.isEmpty ? nil : keyword)
            bills = fetched.sorted { $0.date > $1.date }
            groupedBills = bills.groupedByDate()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Filter By Type

    func filterByType(_ type: BillType?) async {
        selectedType = type
        await loadBills()
    }
}
