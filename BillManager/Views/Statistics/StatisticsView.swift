import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @State var viewModel: StatisticsViewModel
    var ledgers: [Ledger]

    // Services for dependency injection context
    let billService: BillService
    let statisticsService: StatisticsService

    var body: some View {
        VStack(spacing: 0) {
            CustomNavBar(
                title: "统计",
                rightContent: {
                    NavBarMenuButton(
                        icon: viewModel.selectedLedger?.icon ?? "book.fill",
                        color: AppColors.primary
                    ) {
                        ForEach(ledgers.filter { !$0.isArchived }) { ledger in
                            Button {
                                UserDefaults.standard.set(ledger.id.uuidString, forKey: AppConstants.lastSelectedLedgerIdKey)
                                Task { await viewModel.loadStatistics(for: ledger, range: viewModel.selectedRange) }
                            } label: {
                                HStack {
                                    Image(systemName: ledger.icon)
                                    Text(ledger.name)
                                    if ledger.id == viewModel.selectedLedger?.id {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                }
            )

            ScrollView {
                VStack(spacing: 20) {
                    timeRangePicker

                    typeSelector

                    summaryCard

                    if !viewModel.categoryStats.isEmpty {
                        pieChartSection

                        categoryBreakdownSection
                    } else {
                        emptyState
                    }
                }
                .padding()
            }
        }
        .background(AppColors.background)
        .task {
            let currentLedger = resolveCurrentLedger()
            if let ledger = currentLedger {
                await viewModel.loadStatistics(for: ledger, range: viewModel.selectedRange)
            }
        }
    }

    // MARK: - Resolve Current Ledger

    private func resolveCurrentLedger() -> Ledger? {
        if let lastSelectedId = UserDefaults.standard.string(forKey: AppConstants.lastSelectedLedgerIdKey),
           let uuid = UUID(uuidString: lastSelectedId) {
            return ledgers.first { $0.id == uuid }
        }
        return ledgers.first
    }

    // MARK: - Time Range Picker

    private var timeRangePicker: some View {
        HStack(spacing: 8) {
            ForEach([TimeRange.week, .month, .year], id: \.self) { range in
                Button {
                    viewModel.selectedRange = range
                } label: {
                    Text(range.displayName)
                        .font(.system(size: 14, weight: viewModel.selectedRange == range ? .semibold : .regular))
                        .foregroundColor(viewModel.selectedRange == range ? .white : AppColors.textTertiary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(viewModel.selectedRange == range ? AppColors.primary : AppColors.cardBackground)
                        )
                        .shadowLight()
                }
            }
        }
    }

    // MARK: - Type Selector

    private var typeSelector: some View {
        HStack(spacing: 0) {
            Button {
                viewModel.selectedBillType = .income
            } label: {
                Text("收入")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(viewModel.selectedBillType == .income ? AppColors.textPrimary : AppColors.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(viewModel.selectedBillType == .income ? AppColors.cardBackground : Color.clear)
                    )
            }

            Button {
                viewModel.selectedBillType = .expense
            } label: {
                Text("支出")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(viewModel.selectedBillType == .expense ? AppColors.textPrimary : AppColors.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(viewModel.selectedBillType == .expense ? AppColors.cardBackground : Color.clear)
                    )
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(AppColors.backgroundAlt)
        )
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(spacing: 12) {
            Rectangle()
                .fill(AppGradients.primaryHorizontal)
                .frame(height: 3)

            Text(viewModel.selectedBillType == .expense ? "总支出" : "总收入")
                .font(AppTypography.bodySm)
                .fontWeight(.medium)
                .foregroundColor(AppColors.textTertiary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("¥")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(AppColors.textTertiary)
                Text(viewModel.totalAmount.currencyFormatted)
                    .font(AppTypography.amountLarge)
                    .foregroundColor(AppColors.textPrimary)
            }

            Text("共 \(viewModel.filteredBills.count) 笔")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(AppColors.cardBackground)
        .cornerRadius(AppCornerRadius.extraLarge)
        .shadowLight()
    }

    // MARK: - Pie Chart Section

    private var pieChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("分类占比")
                .font(AppTypography.h3)
                .foregroundColor(AppColors.textPrimary)

            ZStack {
                if #available(iOS 17.0, macOS 14.0, *) {
                    Chart(viewModel.categoryStats) { stat in
                        SectorMark(
                            angle: .value("金额", stat.amount),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(Color(hex: stat.colorHex))
                        .cornerRadius(4)
                    }
                    .frame(height: 200)
                }

                VStack(spacing: 2) {
                    Text("总计")
                        .font(AppTypography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textTertiary)
                    Text(viewModel.totalAmount.currencyFormatted)
                        .font(AppTypography.amountMedium)
                        .foregroundColor(AppColors.textPrimary)
                }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(viewModel.categoryStats.prefix(6)) { stat in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(hex: stat.colorHex))
                            .frame(width: 12, height: 12)

                        Text(stat.categoryName)
                            .font(AppTypography.bodySm)
                            .foregroundColor(AppColors.textPrimary)

                        Spacer()

                        Text(String(format: "%.1f%%", stat.percentage))
                            .font(AppTypography.bodySm)
                            .fontWeight(.medium)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
            }
        }
        .padding(AppSpacing.spacing5)
        .background(AppColors.cardBackground)
        .cornerRadius(AppCornerRadius.extraLarge)
        .shadowLight()
    }

    // MARK: - Category Breakdown Section

    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分类明细")
                .font(AppTypography.h4)
                .foregroundColor(AppColors.textPrimary)

            ForEach(viewModel.categoryStats) { stat in
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: stat.colorHex).opacity(0.2))
                            .frame(width: 40, height: 40)
                        Image(systemName: stat.icon)
                            .foregroundColor(Color(hex: stat.colorHex))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(stat.categoryName)
                            .font(AppTypography.body)
                        Text(String(format: "%.1f%%", stat.percentage))
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }

                    Spacer()

                    Text(stat.amount.currencyFormatted)
                        .font(AppTypography.body)
                        .fontWeight(.medium)
                        .foregroundColor(viewModel.selectedBillType == .expense ? AppColors.expense : AppColors.income)
                }
                .padding(.vertical, 4)

                if stat.id != viewModel.categoryStats.last?.id {
                    Divider()
                }
            }
        }
        .padding(AppSpacing.spacing5)
        .background(AppColors.cardBackground)
        .cornerRadius(AppCornerRadius.extraLarge)
        .shadowLight()
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.pie")
                .font(.system(size: 60))
                .foregroundColor(AppColors.textTertiary)

            Text("暂无数据")
                .font(.title3)
                .foregroundColor(AppColors.textSecondary)

            Text("选择时间范围内没有账单记录")
                .font(.subheadline)
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

#Preview {
    let container = try! ModelContainer(for: Ledger.self, Bill.self, Category.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let ctx = container.mainContext
    let billRepo = BillRepository(modelContext: ctx)
    let billService = BillService(billRepository: billRepo)
    let statisticsService = StatisticsService()
    return StatisticsView(
        viewModel: StatisticsViewModel(billService: billService, statisticsService: statisticsService),
        ledgers: [],
        billService: billService,
        statisticsService: statisticsService
    )
    .modelContainer(container)
}
