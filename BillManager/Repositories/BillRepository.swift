import Foundation
import SwiftData

// MARK: - BillRepository

@MainActor
final class BillRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Fetch

    func fetchBills(for ledger: Ledger, in range: TimeRange? = nil) throws -> [Bill] {
        var descriptor = FetchDescriptor<Bill>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        let ledgerId = ledger.id
        if let range = range {
            let (start, end) = range.dateRange()
            descriptor.predicate = #Predicate<Bill> { bill in
                bill.ledger?.id == ledgerId &&
                bill.date >= start &&
                bill.date <= end
            }
        } else {
            descriptor.predicate = #Predicate<Bill> { bill in
                bill.ledger?.id == ledgerId
            }
        }

        return try modelContext.fetch(descriptor)
    }

    func fetchBills(for ledger: Ledger, type: BillType? = nil, keyword: String? = nil) throws -> [Bill] {
        let allBills = try fetchBills(for: ledger)

        var result = allBills

        if let type = type {
            result = result.filter { $0.type == type }
        }

        if let keyword = keyword, !keyword.isEmpty {
            result = result.filter {
                $0.categoryName.localizedCaseInsensitiveContains(keyword) ||
                ($0.note?.localizedCaseInsensitiveContains(keyword) ?? false)
            }
        }

        return result
    }

    // MARK: - Create

    @discardableResult
    func createBill(
        amount: Double,
        type: BillType,
        categoryName: String,
        categoryIcon: String,
        categoryColorHex: String,
        note: String?,
        date: Date,
        ledger: Ledger
    ) throws -> Bill {
        let bill = Bill(
            amount: amount,
            type: type,
            categoryName: categoryName,
            categoryIcon: categoryIcon,
            categoryColorHex: categoryColorHex,
            note: note,
            date: date
        )
        modelContext.insert(bill)
        bill.ledger = ledger
        if ledger.bills == nil { ledger.bills = [] }
        ledger.bills?.append(bill)
        try modelContext.save()
        return bill
    }

    // MARK: - Update

    func updateBill(
        _ bill: Bill,
        amount: Double? = nil,
        type: BillType? = nil,
        categoryName: String? = nil,
        categoryIcon: String? = nil,
        categoryColorHex: String? = nil,
        note: String? = nil,
        date: Date? = nil
    ) throws {
        if let amount = amount { bill.amount = amount }
        if let type = type { bill.type = type }
        if let categoryName = categoryName { bill.categoryName = categoryName }
        if let categoryIcon = categoryIcon { bill.categoryIcon = categoryIcon }
        if let categoryColorHex = categoryColorHex { bill.categoryColorHex = categoryColorHex }
        if let note = note { bill.note = note }
        if let date = date { bill.date = date }
        bill.updatedAt = Date()
        try modelContext.save()
    }

    // MARK: - Delete

    func deleteBill(_ bill: Bill) throws {
        modelContext.delete(bill)
        try modelContext.save()
    }

    func deleteAllBills(in ledger: Ledger) throws {
        let bills = try fetchBills(for: ledger)
        for bill in bills {
            modelContext.delete(bill)
        }
        try modelContext.save()
    }
}
