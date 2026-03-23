import Foundation
import SwiftData

enum BillType: String, Codable, CaseIterable {
    case income = "income"
    case expense = "expense"

    var displayName: String {
        switch self {
        case .income: return "收入"
        case .expense: return "支出"
        }
    }

    var icon: String {
        switch self {
        case .income: return "arrow.down.circle.fill"
        case .expense: return "arrow.up.circle.fill"
        }
    }
}

@Model
final class Bill {
    var id: UUID
    var amount: Double
    var typeRawValue: String
    var categoryName: String
    var categoryIcon: String
    var categoryColorHex: String
    var note: String?
    var date: Date
    var createdAt: Date
    var updatedAt: Date

    var ledger: Ledger?

    var type: BillType {
        get { BillType(rawValue: typeRawValue) ?? .expense }
        set { typeRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        amount: Double,
        type: BillType,
        categoryName: String,
        categoryIcon: String = "circle.fill",
        categoryColorHex: String = "#007AFF",
        note: String? = nil,
        date: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.amount = amount
        self.typeRawValue = type.rawValue
        self.categoryName = categoryName
        self.categoryIcon = categoryIcon
        self.categoryColorHex = categoryColorHex
        self.note = note
        self.date = date
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}