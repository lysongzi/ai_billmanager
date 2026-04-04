import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Ledger.createdAt, order: .reverse) private var ledgers: [Ledger]

    @State private var selectedTab: Int = 0
    @State private var showingAddRecord: Bool = false

    let ledgerService: LedgerService
    let billService: BillService
    let statisticsService: StatisticsService

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab Content
            Group {
                switch selectedTab {
                case 0:
                    NavigationStack {
                        LedgerListView(
                            viewModel: LedgerListViewModel(ledgerService: ledgerService)
                        )
                    }
                case 1:
                    StatisticsView(
                        viewModel: StatisticsViewModel(
                            billService: billService,
                            statisticsService: statisticsService
                        ),
                        ledgers: ledgers,
                        billService: billService,
                        statisticsService: statisticsService
                    )
                case 2:
                    SettingsView(
                        viewModel: SettingsViewModel(
                            ledgerRepository: LedgerRepository(modelContext: modelContext)
                        ),
                        ledgers: ledgers,
                        ledgerService: ledgerService,
                        billService: billService,
                        statisticsService: statisticsService
                    )
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 80)

            // Custom Bottom Nav Bar
            VStack(spacing: 0) {
                Spacer()
                BottomNavBar(
                    selectedTab: $selectedTab,
                    onAddTap: { showingAddRecord = true }
                )
            }
            .ignoresSafeArea(.keyboard)
        }
        .sheet(isPresented: $showingAddRecord) {
            AddRecordView(
                viewModel: AddRecordViewModel(
                    billService: billService,
                    categoryRepository: CategoryRepository(modelContext: modelContext)
                ),
                currentLedger: currentLedger
            )
        }
        .ignoresSafeArea(.keyboard)
    }

    private var currentLedger: Ledger? {
        if let lastSelectedId = UserDefaults.standard.string(forKey: AppConstants.lastSelectedLedgerIdKey),
           let uuid = UUID(uuidString: lastSelectedId) {
            return ledgers.first { $0.id == uuid }
        }
        return ledgers.first
    }
}

#Preview {
    ContentView(
        ledgerService: {
            let container = try! ModelContainer(for: Ledger.self, Bill.self, Category.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let ctx = container.mainContext
            let ledgerRepo = LedgerRepository(modelContext: ctx)
            let categoryRepo = CategoryRepository(modelContext: ctx)
            return LedgerService(ledgerRepository: ledgerRepo, categoryRepository: categoryRepo)
        }(),
        billService: {
            let container = try! ModelContainer(for: Ledger.self, Bill.self, Category.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let ctx = container.mainContext
            return BillService(billRepository: BillRepository(modelContext: ctx))
        }(),
        statisticsService: StatisticsService()
    )
    .modelContainer(for: [Ledger.self, Bill.self, Category.self], inMemory: true)
}
