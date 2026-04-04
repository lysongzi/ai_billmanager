import Foundation
import SwiftData

// MARK: - CategoryRepository

@MainActor
final class CategoryRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Default Categories Data

    static let defaultExpenseCategories: [(name: String, icon: String, colorHex: String)] = [
        ("餐饮",   "fork.knife",                 "#FF6B6B"),
        ("交通",   "car.fill",                    "#4ECDC4"),
        ("购物",   "bag.fill",                    "#45B7D1"),
        ("娱乐",   "gamecontroller.fill",          "#96CEB4"),
        ("居住",   "house.fill",                  "#FFEAA7"),
        ("医疗",   "cross.case.fill",              "#DDA0DD"),
        ("通讯",   "phone.fill",                  "#98D8C8"),
        ("其他",   "ellipsis.circle.fill",         "#B8B8B8")
    ]

    static let defaultIncomeCategories: [(name: String, icon: String, colorHex: String)] = [
        ("工资",     "dollarsign.circle.fill",          "#2ECC71"),
        ("奖金",     "gift.fill",                       "#F39C12"),
        ("投资收益", "chart.line.uptrend.xyaxis",        "#3498DB"),
        ("其他收入", "plus.circle.fill",                 "#95A5A6")
    ]

    // MARK: - Fetch

    func fetchCategories(for ledger: Ledger, type: BillType? = nil) throws -> [Category] {
        let ledgerId = ledger.id
        var descriptor: FetchDescriptor<Category>

        if let type = type {
            let typeRaw = type.rawValue
            descriptor = FetchDescriptor<Category>(
                predicate: #Predicate<Category> { category in
                    category.ledger?.id == ledgerId && category.typeRawValue == typeRaw
                }
            )
        } else {
            descriptor = FetchDescriptor<Category>(
                predicate: #Predicate<Category> { category in
                    category.ledger?.id == ledgerId
                }
            )
        }

        return try modelContext.fetch(descriptor)
    }

    // MARK: - Create

    @discardableResult
    func createCategory(
        name: String,
        icon: String,
        colorHex: String,
        type: BillType,
        ledger: Ledger
    ) throws -> Category {
        let category = Category(name: name, icon: icon, colorHex: colorHex, type: type)
        modelContext.insert(category)
        category.ledger = ledger
        if ledger.categories == nil { ledger.categories = [] }
        ledger.categories?.append(category)
        try modelContext.save()
        return category
    }

    // MARK: - Update

    func updateCategory(
        _ category: Category,
        name: String? = nil,
        icon: String? = nil,
        colorHex: String? = nil
    ) throws {
        if let name = name { category.name = name }
        if let icon = icon { category.icon = icon }
        if let colorHex = colorHex { category.colorHex = colorHex }
        try modelContext.save()
    }

    // MARK: - Delete

    func deleteCategory(_ category: Category) throws {
        modelContext.delete(category)
        try modelContext.save()
    }

    // MARK: - Create Default Categories

    func createDefaultCategories(for ledger: Ledger) throws {
        for (name, icon, colorHex) in Self.defaultExpenseCategories {
            let category = Category(name: name, icon: icon, colorHex: colorHex, type: .expense)
            modelContext.insert(category)
            category.ledger = ledger
            if ledger.categories == nil { ledger.categories = [] }
            ledger.categories?.append(category)
        }

        for (name, icon, colorHex) in Self.defaultIncomeCategories {
            let category = Category(name: name, icon: icon, colorHex: colorHex, type: .income)
            modelContext.insert(category)
            category.ledger = ledger
            if ledger.categories == nil { ledger.categories = [] }
            ledger.categories?.append(category)
        }

        try modelContext.save()
    }
}
