import Foundation
import SwiftData

@Model
final class Ledger {
    var id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var createdAt: Date
    var isArchived: Bool

    @Relationship(deleteRule: .cascade, inverse: \Bill.ledger)
    var bills: [Bill]?

    @Relationship(deleteRule: .cascade, inverse: \Category.ledger)
    var categories: [Category]?

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "book.fill",
        colorHex: String = "#007AFF",
        createdAt: Date = Date(),
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.isArchived = isArchived
        self.bills = []
        self.categories = []
    }

    var totalIncome: Double {
        bills?.reduce(0) { $0 + ($1.type == .income ? $1.amount : 0) } ?? 0
    }

    var totalExpense: Double {
        bills?.reduce(0) { $0 + ($1.type == .expense ? $1.amount : 0) } ?? 0
    }

    var balance: Double {
        totalIncome - totalExpense
    }
}