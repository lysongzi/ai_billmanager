import SwiftUI
import SwiftData

@main
struct BillManagerApp: App {
    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Ledger.self,
            Bill.self,
            Category.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - RootView (依赖注入根节点)

struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ContentView(
            ledgerService: makeLedgerService(),
            billService: makeBillService(),
            statisticsService: StatisticsService()
        )
        .onAppear {
            initializeIfNeeded()
        }
    }

    // MARK: - Factory Methods

    private func makeLedgerService() -> LedgerService {
        let ledgerRepo = LedgerRepository(modelContext: modelContext)
        let categoryRepo = CategoryRepository(modelContext: modelContext)
        return LedgerService(ledgerRepository: ledgerRepo, categoryRepository: categoryRepo)
    }

    private func makeBillService() -> BillService {
        let billRepo = BillRepository(modelContext: modelContext)
        return BillService(billRepository: billRepo)
    }

    private func initializeIfNeeded() {
        // Run on MainActor since LedgerService is @MainActor
        let service = makeLedgerService()
        Task { @MainActor in
            try? service.initializeDefaultLedgerIfNeeded()
        }
    }
}
