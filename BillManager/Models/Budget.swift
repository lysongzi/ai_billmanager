import Foundation
import SwiftData

@Model
final class Budget {
    var id: UUID
    var amount: Double
    var periodRawValue: String
    var categoryName: String?
    var startDate: Date
    var isEnabled: Bool
    var ledger: Ledger?
    
    var period: BudgetPeriod {
        get { BudgetPeriod(rawValue: periodRawValue) ?? .monthly }
        set { periodRawValue = newValue.rawValue }
    }
    
    init(
        id: UUID = UUID(),
        amount: Double,
        period: BudgetPeriod = .monthly,
        categoryName: String? = nil,
        startDate: Date = Date(),
        isEnabled: Bool = true,
        ledger: Ledger? = nil
    ) {
        self.id = id
        self.amount = amount
        self.periodRawValue = period.rawValue
        self.categoryName = categoryName
        self.startDate = startDate
        self.isEnabled = isEnabled
        self.ledger = ledger
    }
    
    enum BudgetPeriod: String, Codable, CaseIterable {
        case weekly
        case monthly
        case yearly
        
        var displayName: String {
            switch self {
            case .weekly: return "周"
            case .monthly: return "月"
            case .yearly: return "年"
            }
        }
    }
}

struct BudgetProgress {
    var budget: Budget
    var spentAmount: Double
    var remainingAmount: Double
    var progressPercentage: Double
    var isOverBudget: Bool
    
    init(budget: Budget, spentAmount: Double) {
        self.budget = budget
        self.spentAmount = spentAmount
        self.remainingAmount = budget.amount - spentAmount
        self.progressPercentage = budget.amount > 0 ? (spentAmount / budget.amount) * 100 : 0
        self.isOverBudget = spentAmount > budget.amount
    }
}