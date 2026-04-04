import Foundation
import SwiftData

// MARK: - BillServiceError

enum BillServiceError: LocalizedError {
    case invalidAmount
    case missingCategory
    case futureDateNotAllowed

    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "金额必须大于 0"
        case .missingCategory:
            return "请选择分类"
        case .futureDateNotAllowed:
            return "日期不能是未来时间"
        }
    }
}

// MARK: - BillService

@MainActor
final class BillService {
    private let billRepository: BillRepository

    init(billRepository: BillRepository) {
        self.billRepository = billRepository
    }

    // MARK: - Create Bill

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
        guard amount > 0 else { throw BillServiceError.invalidAmount }
        guard !categoryName.isEmpty else { throw BillServiceError.missingCategory }

        return try billRepository.createBill(
            amount: amount,
            type: type,
            categoryName: categoryName,
            categoryIcon: categoryIcon,
            categoryColorHex: categoryColorHex,
            note: note.flatMap { $0.isEmpty ? nil : $0 },
            date: date,
            ledger: ledger
        )
    }

    // MARK: - Update Bill

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
        if let amount = amount {
            guard amount > 0 else { throw BillServiceError.invalidAmount }
        }

        try billRepository.updateBill(
            bill,
            amount: amount,
            type: type,
            categoryName: categoryName,
            categoryIcon: categoryIcon,
            categoryColorHex: categoryColorHex,
            note: note,
            date: date
        )
    }

    // MARK: - Delete Bill

    func deleteBill(_ bill: Bill) throws {
        try billRepository.deleteBill(bill)
    }

    // MARK: - Fetch Bills

    func fetchBills(for ledger: Ledger, in range: TimeRange? = nil) throws -> [Bill] {
        try billRepository.fetchBills(for: ledger, in: range)
    }

    func fetchBills(for ledger: Ledger, type: BillType? = nil, keyword: String? = nil) throws -> [Bill] {
        try billRepository.fetchBills(for: ledger, type: type, keyword: keyword)
    }
}
