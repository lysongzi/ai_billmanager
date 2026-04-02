import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var ledgers: [Ledger]

    @State private var selectedLedger: Ledger?
    @State private var selectedTimeRange: TimeRange = .month
    @State private var selectedBillType: BillType = .expense

    private var currentLedger: Ledger? {
        if let selected = selectedLedger {
            return selected
        }
        if let lastSelectedId = UserDefaults.standard.string(forKey: "lastSelectedLedgerId"),
           let uuid = UUID(uuidString: lastSelectedId) {
            return ledgers.first { $0.id == uuid }
        }
        return ledgers.first
    }

    private var filteredBills: [Bill] {
        guard let ledger = currentLedger else { return [] }
        let allBills = ledger.bills ?? []
        let (startDate, endDate) = selectedTimeRange.dateRange()
        return allBills.filter { bill in
            bill.date >= startDate && bill.date <= endDate && bill.type == selectedBillType
        }
    }

    private var totalAmount: Double {
        filteredBills.reduce(0) { $0 + $1.amount }
    }

    private var categoryStats: [CategoryStat] {
        let grouped = Dictionary(grouping: filteredBills) { $0.categoryName }

        return grouped.map { (categoryName, bills) in
            let total = bills.reduce(0) { $0 + $1.amount }
            let percentage = totalAmount > 0 ? (total / totalAmount) * 100 : 0
            let firstBill = bills.first!

            return CategoryStat(
                categoryName: categoryName,
                icon: firstBill.categoryIcon,
                colorHex: firstBill.categoryColorHex,
                amount: total,
                percentage: percentage,
                type: selectedBillType
            )
        }
        .sorted { $0.amount > $1.amount }
    }

    private var dailyStats: [DailyStat] {
        let (startDate, endDate) = selectedTimeRange.dateRange()
        var stats: [DailyStat] = []

        let allBills = currentLedger?.bills ?? []
        let periodBills = allBills.filter { bill in
            bill.date >= startDate && bill.date <= endDate
        }

        var currentDate = startDate
        while currentDate <= endDate {
            let dayBills = periodBills.filter { bill in
                Calendar.current.isDate(bill.date, inSameDayAs: currentDate)
            }

            let income = dayBills.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let expense = dayBills.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }

            stats.append(DailyStat(date: currentDate, income: income, expense: expense))

            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? endDate
        }

        return stats
    }

    var body: some View {
        VStack(spacing: 0) {
            CustomNavBar(
                title: "统计",
                rightContent: {
                    NavBarMenuButton(
                        icon: currentLedger?.icon ?? "book.fill",
                        color: Color(hex: "#4ECDC4")
                    ) {
                        ForEach(ledgers.filter { !$0.isArchived }) { ledger in
                            Button {
                                selectedLedger = ledger
                                UserDefaults.standard.set(ledger.id.uuidString, forKey: "lastSelectedLedgerId")
                            } label: {
                                HStack {
                                    Image(systemName: ledger.icon)
                                    Text(ledger.name)
                                    if ledger.id == currentLedger?.id {
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

                    if !categoryStats.isEmpty {
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
    }

    private var ledgerPicker: some View {
        Menu {
            ForEach(ledgers.filter { !$0.isArchived }) { ledger in
                Button {
                    selectedLedger = ledger
                    UserDefaults.standard.set(ledger.id.uuidString, forKey: "lastSelectedLedgerId")
                } label: {
                    HStack {
                        Image(systemName: ledger.icon)
                        Text(ledger.name)
                        if ledger.id == currentLedger?.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                Image(systemName: currentLedger?.icon ?? "book.fill")
                Text(currentLedger?.name ?? "选择账本")
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .font(.headline)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
        }
    }

    private var timeRangePicker: some View {
        HStack(spacing: 8) {
            ForEach([TimeRange.week, .month, .year], id: \.self) { range in
                Button {
                    selectedTimeRange = range
                } label: {
                    Text(range.displayName)
                        .font(.system(size: 14, weight: selectedTimeRange == range ? .semibold : .regular))
                        .foregroundColor(selectedTimeRange == range ? .white : Color(red: 168/255, green: 162/255, blue: 158/255))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(selectedTimeRange == range ? Color(red: 245/255, green: 158/255, blue: 11/255) : Color.white)
                        )
                        .shadow(color: Color.black.opacity(selectedTimeRange == range ? 0.15 : 0.04), radius: selectedTimeRange == range ? 4 : 2, x: 0, y: 2)
                }
            }
        }
    }

    private var typeSelector: some View {
        HStack(spacing: 0) {
            Button {
                selectedBillType = .income
            } label: {
                Text("收入")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(selectedBillType == .income ? Color(red: 28/255, green: 25/255, blue: 23/255) : Color(red: 168/255, green: 162/255, blue: 158/255))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(selectedBillType == .income ? Color.white : Color.clear)
                    )
                    .shadow(color: Color.black.opacity(selectedBillType == .income ? 0.04 : 0), radius: 4, x: 0, y: 2)
            }
            
            Button {
                selectedBillType = .expense
            } label: {
                Text("支出")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(selectedBillType == .expense ? Color(red: 28/255, green: 25/255, blue: 23/255) : Color(red: 168/255, green: 162/255, blue: 158/255))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(selectedBillType == .expense ? Color.white : Color.clear)
                    )
                    .shadow(color: Color.black.opacity(selectedBillType == .expense ? 0.04 : 0), radius: 4, x: 0, y: 2)
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(Color(red: 245/255, green: 245/255, blue: 244/255))
        )
    }

    private var summaryCard: some View {
        VStack(spacing: 12) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 245/255, green: 158/255, blue: 11/255).opacity(0.6),
                            Color(red: 244/255, green: 63/255, blue: 94/255).opacity(0.6),
                            Color(red: 245/255, green: 158/255, blue: 11/255).opacity(0.6)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 3)

            Text(selectedBillType == .expense ? "总支出" : "总收入")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(red: 168/255, green: 162/255, blue: 158/255))

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("¥")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color(red: 168/255, green: 162/255, blue: 158/255))
                Text(totalAmount.currencyFormatted)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(Color(red: 28/255, green: 25/255, blue: 23/255))
            }

            Text("共 \(filteredBills.count) 笔")
                .font(.system(size: 12))
                .foregroundColor(Color(red: 120/255, green: 113/255, blue: 108/255))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color.white)
        .cornerRadius(40)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }

    private var pieChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("分类占比")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 28/255, green: 25/255, blue: 23/255))
            
            ZStack {
                if #available(iOS 17.0, macOS 14.0, *) {
                    Chart(categoryStats) { stat in
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
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 168/255, green: 162/255, blue: 158/255))
                    Text(totalAmount.currencyFormatted)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(red: 28/255, green: 25/255, blue: 23/255))
                }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(categoryStats.prefix(6)) { stat in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(hex: stat.colorHex))
                            .frame(width: 12, height: 12)

                        Text(stat.categoryName)
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 28/255, green: 25/255, blue: 23/255))

                        Spacer()

                        Text(String(format: "%.1f%%", stat.percentage))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(red: 168/255, green: 162/255, blue: 158/255))
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(40)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }

    private var trendChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("趋势变化")
                .font(.headline)

            if #available(iOS 17.0, macOS 14.0, *) {
                Chart(dailyStats) { stat in
                    LineMark(
                        x: .value("日期", stat.date),
                        y: .value("金额", selectedBillType == .expense ? stat.expense : stat.income)
                    )
                    .foregroundStyle(selectedBillType == .expense ? Color.red : Color.green)

                    AreaMark(
                        x: .value("日期", stat.date),
                        y: .value("金额", selectedBillType == .expense ? stat.expense : stat.income)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                (selectedBillType == .expense ? Color.red : Color.green).opacity(0.3),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .frame(height: 180)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.day().month())
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分类明细")
                .font(.headline)

            ForEach(categoryStats) { stat in
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
                            .font(.body)
                        Text(String(format: "%.1f%%", stat.percentage))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text(stat.amount.currencyFormatted)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(selectedBillType == .expense ? .red : .green)
                }
                .padding(.vertical, 4)

                if stat.id != categoryStats.last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.pie")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("暂无数据")
                .font(.title3)
                .foregroundColor(.secondary)

            Text("选择时间范围内没有账单记录")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

#Preview {
    StatisticsView()
        .modelContainer(for: [Ledger.self, Bill.self, Category.self], inMemory: true)
}