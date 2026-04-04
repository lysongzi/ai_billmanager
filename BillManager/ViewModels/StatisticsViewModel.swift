import Foundation
import Observation

// MARK: - StatisticsViewModel

@Observable
@MainActor
final class StatisticsViewModel {
    var statistics: Statistics? = nil
    var categoryStats: [CategoryStat] = []
    var dailyStats: [DailyStat] = []
    var selectedRange: TimeRange = .month {
        didSet {
            if let ledger = selectedLedger {
                Task { await loadStatistics(for: ledger, range: selectedRange) }
            }
        }
    }
    var selectedBillType: BillType = .expense {
        didSet {
            updateFilteredStats()
        }
    }
    var selectedLedger: Ledger? = nil
    var isLoading: Bool = false
    var errorMessage: String? = nil

    // All bills in range (both types)
    private var allBillsInRange: [Bill] = []

    var filteredBills: [Bill] { allBillsInRange.filter { $0.type == selectedBillType } }
    var totalAmount: Double { filteredBills.reduce(0) { $0 + $1.amount } }

    private let billService: BillService
    private let statisticsService: StatisticsService

    init(billService: BillService, statisticsService: StatisticsService) {
        self.billService = billService
        self.statisticsService = statisticsService
    }

    // MARK: - Load Statistics

    func loadStatistics(for ledger: Ledger, range: TimeRange) async {
        selectedLedger = ledger
        isLoading = true
        errorMessage = nil

        do {
            allBillsInRange = try billService.fetchBills(for: ledger, in: range)
            statistics = statisticsService.calculateStatistics(bills: allBillsInRange)
            updateFilteredStats()
            dailyStats = statisticsService.calculateDailyStats(bills: allBillsInRange, in: range)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Update Filtered Stats

    private func updateFilteredStats() {
        let filtered = allBillsInRange.filter { $0.type == selectedBillType }
        categoryStats = statisticsService.calculateCategoryStats(bills: filtered)
    }
}
