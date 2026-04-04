import SwiftUI
import SwiftData
#if !os(macOS)
import UIKit
#endif

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("defaultCurrency") private var defaultCurrency: String = "CNY"
    @AppStorage("dateFormat") private var dateFormat: String = "yyyy-MM-dd"

    @State private var showingLedgerManager = false
    @State private var showingAbout = false
    @State private var showingDeleteAlert = false

    var viewModel: SettingsViewModel
    var ledgers: [Ledger]

    // Services passed through for sub-views
    let ledgerService: LedgerService
    let billService: BillService
    let statisticsService: StatisticsService

    var currentLedger: Ledger? {
        if let lastSelectedId = UserDefaults.standard.string(forKey: AppConstants.lastSelectedLedgerIdKey),
           let uuid = UUID(uuidString: lastSelectedId) {
            return ledgers.first { $0.id == uuid }
        }
        return ledgers.first
    }

    var body: some View {
        VStack(spacing: 0) {
            CustomNavBar(title: "设置")

            ScrollView {
                VStack(spacing: 24) {
                    ledgerSection

                    generalSection

                    dataSection

                    aboutSection
                }
                .padding()
            }
        }
        .background(AppColors.background)
        .sheet(isPresented: $showingLedgerManager) {
            NavigationStack {
                LedgerListView(
                    viewModel: LedgerListViewModel(ledgerService: ledgerService)
                )
            }
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .alert("确认删除所有数据", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("清空", role: .destructive) {
                Task {
                    try? await viewModel.clearAllData()
                }
            }
        } message: {
            Text("此操作将删除所有账本和账单数据，且不可恢复。")
        }
    }

    private var ledgerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("账本")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.textTertiary)

            VStack(spacing: 0) {
                settingsRow(
                    icon: "book.fill",
                    iconBgColor: AppColors.primary.opacity(0.15),
                    iconColor: AppColors.primary,
                    title: "当前账本",
                    value: currentLedger?.name ?? "默认账本"
                )

                Divider()
                    .padding(.leading, 60)

                Button {
                    showingLedgerManager = true
                } label: {
                    settingsRow(
                        icon: "folder.fill",
                        iconBgColor: AppColors.info.opacity(0.15),
                        iconColor: AppColors.info,
                        title: "管理账本",
                        showChevron: true
                    )
                }
            }
            .background(AppColors.cardBackground)
            .cornerRadius(AppCornerRadius.extraLarge)
            .shadowLight()
        }
    }

    private func settingsRow(icon: String, iconBgColor: Color, iconColor: Color, title: String, value: String? = nil, showChevron: Bool = false) -> some View {
        HStack(spacing: AppSpacing.spacing4) {
            ZStack {
                Circle()
                    .fill(iconBgColor)
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
            }

            Text(title)
                .font(AppTypography.h4)
                .foregroundColor(AppColors.textPrimary)

            Spacer()

            if let value = value {
                Text(value)
                    .font(AppTypography.bodySm)
                    .foregroundColor(AppColors.textTertiary)
            }

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(AppSpacing.spacing4)
    }

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("通用")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.textTertiary)

            VStack(spacing: 0) {
                HStack(spacing: AppSpacing.spacing4) {
                    ZStack {
                        Circle()
                            .fill(AppColors.income.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(AppColors.income)
                    }

                    Text("货币")
                        .font(AppTypography.h4)
                        .foregroundColor(AppColors.textPrimary)

                    Spacer()

                    Picker("", selection: $defaultCurrency) {
                        Text("人民币 (CNY)").tag("CNY")
                        Text("美元 (USD)").tag("USD")
                        Text("欧元 (EUR)").tag("EUR")
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                .padding(AppSpacing.spacing4)

                Divider()
                    .padding(.leading, 60)

                HStack(spacing: AppSpacing.spacing4) {
                    ZStack {
                        Circle()
                            .fill(Color.indigo.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "calendar")
                            .font(.system(size: 18))
                            .foregroundColor(.indigo)
                    }

                    Text("日期格式")
                        .font(AppTypography.h4)
                        .foregroundColor(AppColors.textPrimary)

                    Spacer()

                    Picker("", selection: $dateFormat) {
                        Text("yyyy-MM-dd").tag("yyyy-MM-dd")
                        Text("yyyy/MM/dd").tag("yyyy/MM/dd")
                        Text("MM/dd").tag("MM/dd")
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                .padding(AppSpacing.spacing4)
            }
            .background(AppColors.cardBackground)
            .cornerRadius(AppCornerRadius.extraLarge)
            .shadowLight()
        }
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("数据")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.textTertiary)

            VStack(spacing: 0) {
                Button {
                    exportData()
                } label: {
                    HStack(spacing: AppSpacing.spacing4) {
                        ZStack {
                            Circle()
                                .fill(AppColors.primary.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18))
                                .foregroundColor(AppColors.primary)
                        }

                        Text("导出数据")
                            .font(AppTypography.h4)
                            .foregroundColor(AppColors.primary)

                        Spacer()
                    }
                    .padding(AppSpacing.spacing4)
                }

                Divider()
                    .padding(.leading, 60)

                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    HStack(spacing: AppSpacing.spacing4) {
                        ZStack {
                            Circle()
                                .fill(AppColors.expense.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: "trash")
                                .font(.system(size: 18))
                                .foregroundColor(AppColors.expense)
                        }

                        Text("清空所有数据")
                            .font(AppTypography.h4)
                            .foregroundColor(AppColors.expense)

                        Spacer()
                    }
                    .padding(AppSpacing.spacing4)
                }
            }
            .background(AppColors.cardBackground)
            .cornerRadius(AppCornerRadius.extraLarge)
            .shadowLight()
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("关于")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.textTertiary)

            VStack(spacing: 0) {
                settingsRow(
                    icon: "info.circle",
                    iconBgColor: Color.gray.opacity(0.15),
                    iconColor: AppColors.textSecondary,
                    title: "版本",
                    value: viewModel.appVersion
                )

                Divider()
                    .padding(.leading, 60)

                Button {
                    showingAbout = true
                } label: {
                    settingsRow(
                        icon: "questionmark.circle",
                        iconBgColor: Color.gray.opacity(0.15),
                        iconColor: AppColors.textSecondary,
                        title: "关于我们",
                        showChevron: true
                    )
                }
            }
            .background(AppColors.cardBackground)
            .cornerRadius(AppCornerRadius.extraLarge)
            .shadowLight()
        }
    }

    private func exportData() {
        guard let ledger = currentLedger,
              let bills = ledger.bills else { return }

        var csvContent = "日期,类型,分类,金额,备注\n"

        for bill in bills.sorted(by: { $0.date > $1.date }) {
            let dateStr = bill.date.formatted(as: dateFormat)
            let typeStr = bill.type == .income ? "收入" : "支出"
            let note = bill.note?.replacingOccurrences(of: ",", with: ";") ?? ""
            let row = "\(dateStr),\(typeStr),\(bill.categoryName),\(bill.amount),\(note)\n"
            csvContent += row
        }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(ledger.name)_账单导出.csv")

        do {
            try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)
#if !os(macOS)
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
#endif
        } catch {
            print("导出失败: \(error)")
        }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppColors.primary)

                    Text("记账管理器")
                        .font(AppTypography.h2)
                        .foregroundColor(AppColors.textPrimary)

                    Text("版本 1.0.0")
                        .font(AppTypography.bodySm)
                        .foregroundColor(AppColors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)

                VStack(alignment: .leading, spacing: 12) {
                    Text("简介")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .fontWeight(.semibold)

                    Text("一款简洁高效的跨平台记账应用，帮助您轻松管理个人财务。")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppSpacing.spacing5)
                .background(AppColors.cardBackground)
                .cornerRadius(AppCornerRadius.xl)
                .shadowLight()

                VStack(alignment: .leading, spacing: 12) {
                    Text("技术栈")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .fontWeight(.semibold)

                    Text("使用 SwiftUI + SwiftData + Swift Charts 构建")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppSpacing.spacing5)
                .background(AppColors.cardBackground)
                .cornerRadius(AppCornerRadius.xl)
                .shadowLight()
            }
            .padding()
        }
        .background(AppColors.background)
        .navigationTitle("关于")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("完成") { dismiss() }
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Ledger.self, Bill.self, Category.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let ctx = container.mainContext
    let ledgerRepo = LedgerRepository(modelContext: ctx)
    let categoryRepo = CategoryRepository(modelContext: ctx)
    let ledgerService = LedgerService(ledgerRepository: ledgerRepo, categoryRepository: categoryRepo)
    let billRepo = BillRepository(modelContext: ctx)
    let billService = BillService(billRepository: billRepo)
    return SettingsView(
        viewModel: SettingsViewModel(ledgerRepository: ledgerRepo),
        ledgers: [],
        ledgerService: ledgerService,
        billService: billService,
        statisticsService: StatisticsService()
    )
    .modelContainer(container)
}
