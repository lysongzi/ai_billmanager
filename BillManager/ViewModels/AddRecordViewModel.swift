import Foundation
import Observation

// MARK: - AddRecordViewModel

@Observable
@MainActor
final class AddRecordViewModel {
    var amount: String = ""
    var selectedType: BillType = .expense {
        didSet { selectedCategory = nil }
    }
    var selectedCategory: Category? = nil
    var categories: [Category] = []
    var note: String = ""
    var selectedDate: Date = Date()
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var isSaved: Bool = false

    var canSave: Bool {
        guard let value = Double(amount), value > 0 else { return false }
        return selectedCategory != nil
    }

    private let billService: BillService
    private let categoryRepository: CategoryRepository

    init(billService: BillService, categoryRepository: CategoryRepository) {
        self.billService = billService
        self.categoryRepository = categoryRepository
    }

    // MARK: - Load Categories

    func loadCategories(for ledger: Ledger) async {
        do {
            categories = try categoryRepository.fetchCategories(for: ledger, type: selectedType)
            if selectedCategory == nil {
                selectedCategory = categories.first
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Reload Categories When Type Changes

    func reloadCategories(for ledger: Ledger) async {
        do {
            categories = try categoryRepository.fetchCategories(for: ledger, type: selectedType)
            selectedCategory = categories.first
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Save Bill

    func save(to ledger: Ledger) async {
        guard let amountValue = Double(amount), amountValue > 0,
              let category = selectedCategory else {
            errorMessage = "请填写有效金额并选择分类"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try billService.createBill(
                amount: amountValue,
                type: selectedType,
                categoryName: category.name,
                categoryIcon: category.icon,
                categoryColorHex: category.colorHex,
                note: note.isEmpty ? nil : note,
                date: selectedDate,
                ledger: ledger
            )
            isSaved = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Reset

    func reset() {
        amount = ""
        selectedType = .expense
        selectedCategory = nil
        categories = []
        note = ""
        selectedDate = Date()
        errorMessage = nil
        isSaved = false
    }
}
