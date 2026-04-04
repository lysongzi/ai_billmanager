import Foundation
import Observation
import SwiftData

// MARK: - SettingsViewModel

@Observable
@MainActor
final class SettingsViewModel {
    var appVersion: String
    var isShowingDeleteConfirm: Bool = false
    var errorMessage: String? = nil

    private let ledgerRepository: LedgerRepository

    init(ledgerRepository: LedgerRepository) {
        self.ledgerRepository = ledgerRepository
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    // MARK: - Clear All Data

    func clearAllData() async throws {
        let ledgers = try ledgerRepository.fetchAllLedgers()
        for ledger in ledgers {
            try ledgerRepository.deleteLedger(ledger)
        }
        UserDefaults.standard.removeObject(forKey: AppConstants.lastSelectedLedgerIdKey)
    }
}
