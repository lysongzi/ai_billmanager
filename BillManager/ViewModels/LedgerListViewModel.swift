import Foundation
import Observation

// MARK: - LedgerListViewModel

@Observable
@MainActor
final class LedgerListViewModel {
    var ledgers: [Ledger] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil

    var activeLedgers: [Ledger] { ledgers.filter { !$0.isArchived } }
    var archivedLedgers: [Ledger] { ledgers.filter { $0.isArchived } }

    private let ledgerService: LedgerService

    init(ledgerService: LedgerService) {
        self.ledgerService = ledgerService
    }

    // MARK: - Load Ledgers

    func loadLedgers() async {
        isLoading = true
        errorMessage = nil
        do {
            ledgers = try ledgerService.fetchAllLedgers()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Create Ledger

    func createLedger(name: String, icon: String, colorHex: String) async {
        do {
            try ledgerService.createLedgerWithDefaults(name: name, icon: icon, colorHex: colorHex)
            await loadLedgers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Update Ledger

    func updateLedger(_ ledger: Ledger, name: String? = nil, icon: String? = nil, colorHex: String? = nil) async {
        do {
            try ledgerService.updateLedger(ledger, name: name, icon: icon, colorHex: colorHex)
            await loadLedgers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Delete Ledger

    func deleteLedger(_ ledger: Ledger) async {
        do {
            try ledgerService.deleteLedger(ledger)
            await loadLedgers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Archive / Restore Ledger

    func archiveLedger(_ ledger: Ledger) async {
        do {
            try ledgerService.archiveLedger(ledger, archived: true)
            await loadLedgers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restoreLedger(_ ledger: Ledger) async {
        do {
            try ledgerService.archiveLedger(ledger, archived: false)
            await loadLedgers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
