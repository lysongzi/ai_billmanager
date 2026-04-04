import Foundation
import SwiftData

// MARK: - LedgerService

@MainActor
final class LedgerService {
    private let ledgerRepository: LedgerRepository
    private let categoryRepository: CategoryRepository

    init(ledgerRepository: LedgerRepository, categoryRepository: CategoryRepository) {
        self.ledgerRepository = ledgerRepository
        self.categoryRepository = categoryRepository
    }

    // MARK: - Create Ledger with Default Categories

    @discardableResult
    func createLedgerWithDefaults(name: String, icon: String, colorHex: String) throws -> Ledger {
        let ledger = try ledgerRepository.createLedger(name: name, icon: icon, colorHex: colorHex)
        try categoryRepository.createDefaultCategories(for: ledger)
        return ledger
    }

    // MARK: - Initialize Default Ledger If Needed

    @discardableResult
    func initializeDefaultLedgerIfNeeded() throws -> Ledger? {
        let all = try ledgerRepository.fetchAllLedgers()
        guard all.isEmpty else { return nil }

        let defaultLedger = try createLedgerWithDefaults(
            name: "默认账本",
            icon: "book.fill",
            colorHex: "#007AFF"
        )

        UserDefaults.standard.set(defaultLedger.id.uuidString, forKey: AppConstants.lastSelectedLedgerIdKey)
        return defaultLedger
    }

    // MARK: - Update Ledger

    func updateLedger(_ ledger: Ledger, name: String? = nil, icon: String? = nil, colorHex: String? = nil) throws {
        try ledgerRepository.updateLedger(ledger, name: name, icon: icon, colorHex: colorHex)
    }

    // MARK: - Delete Ledger

    func deleteLedger(_ ledger: Ledger) throws {
        try ledgerRepository.deleteLedger(ledger)
    }

    // MARK: - Archive Ledger

    func archiveLedger(_ ledger: Ledger, archived: Bool = true) throws {
        try ledgerRepository.archiveLedger(ledger, archived: archived)
    }

    // MARK: - Fetch Ledgers

    func fetchAllLedgers() throws -> [Ledger] {
        try ledgerRepository.fetchAllLedgers()
    }

    func fetchActiveLedgers() throws -> [Ledger] {
        try ledgerRepository.fetchActiveLedgers()
    }
}

// MARK: - AppConstants

enum AppConstants {
    static let lastSelectedLedgerIdKey = "lastSelectedLedgerId"
}
