import Foundation
import SwiftData

// MARK: - LedgerRepository

@MainActor
final class LedgerRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Fetch

    func fetchAllLedgers() throws -> [Ledger] {
        let descriptor = FetchDescriptor<Ledger>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchActiveLedgers() throws -> [Ledger] {
        let descriptor = FetchDescriptor<Ledger>(
            predicate: #Predicate<Ledger> { !$0.isArchived },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    // MARK: - Create

    @discardableResult
    func createLedger(name: String, icon: String, colorHex: String) throws -> Ledger {
        let ledger = Ledger(name: name, icon: icon, colorHex: colorHex)
        modelContext.insert(ledger)
        try modelContext.save()
        return ledger
    }

    // MARK: - Update

    func updateLedger(
        _ ledger: Ledger,
        name: String? = nil,
        icon: String? = nil,
        colorHex: String? = nil
    ) throws {
        if let name = name { ledger.name = name }
        if let icon = icon { ledger.icon = icon }
        if let colorHex = colorHex { ledger.colorHex = colorHex }
        try modelContext.save()
    }

    // MARK: - Delete

    func deleteLedger(_ ledger: Ledger) throws {
        modelContext.delete(ledger)
        try modelContext.save()
    }

    // MARK: - Archive

    func archiveLedger(_ ledger: Ledger, archived: Bool) throws {
        ledger.isArchived = archived
        try modelContext.save()
    }
}
