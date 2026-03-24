import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Ledger.createdAt, order: .reverse) private var ledgers: [Ledger]
    
    @State private var selectedLedger: Ledger?
    @State private var currentMonth: Date = Date()
    @State private var showingLedgerPicker = false
    @State private var showingQuickAdd = false
    
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
    
    private var monthBills: [Bill] {
        guard let ledger = currentLedger else { return [] }
        let (start, end) = getMonthRange(currentMonth)
        return (ledger.bills ?? []).filter { $0.date >= start && $0.date <= end }
    }
    
    private var totalIncome: Double {
        monthBills.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    
    private var totalExpense: Double {
        monthBills.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    private var balance: Double {
        totalIncome - totalExpense
    }
    
    private var recentBills: [Bill] {
        guard let ledger = currentLedger else { return [] }
        return Array((ledger.bills ?? []).sorted { $0.date > $1.date }.prefix(20))
    }
    
    private var groupedBills: [(date: Date, bills: [Bill])] {
        let grouped = Dictionary(grouping: recentBills) { bill in
            Calendar.current.startOfDay(for: bill.date)
        }
        return grouped.map { (date: $0.key, bills: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.date > $1.date }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerSection
                    
                    financialOverviewCard
                    
                    quickActionsSection
                    
                    billListSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("明细")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingLedgerPicker = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: currentLedger?.icon ?? "book.fill")
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingQuickAdd) {
                QuickAddView(ledger: currentLedger ?? Ledger(name: "默认账本")) { bill in
                    saveBill(bill)
                }
            }
            .onAppear {
                if currentLedger == nil && !ledgers.isEmpty {
                    selectedLedger = ledgers.first
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            Button {
                showingLedgerPicker = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: currentLedger?.icon ?? "book.fill")
                        .foregroundColor(Color(hex: "#F6C744"))
                    Text(currentLedger?.name ?? "选择账本")
                        .font(.headline)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button {
                currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(.secondary)
            }
            
            Text(monthYearString)
                .font(.headline)
                .frame(width: 80)
            
            Button {
                currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: currentMonth)
    }
    
    // MARK: - Financial Overview Card
    
    private var financialOverviewCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("本月收支")
                    .font(.headline)
                Spacer()
            }
            
            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("收入")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(totalIncome.currencyFormatted)
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity)
                
                VStack(spacing: 4) {
                    Text("支出")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(totalExpense.currencyFormatted)
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
                .frame(maxWidth: .infinity)
                
                VStack(spacing: 4) {
                    Text("结余")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(balance.currencyFormatted)
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(balance >= 0 ? .green : .red)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Quick Actions Section
    
    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            QuickActionButton(icon: "plus.circle.fill", title: "记一笔", color: Color(hex: "#F6C744")) {
                showingQuickAdd = true
            }
            
            QuickActionButton(icon: "arrow.left.arrow.right", title: "转账", color: Color(hex: "#5B7CFA")) {
                // Transfer action
            }
            
            QuickActionButton(icon: "chart.pie.fill", title: "预算", color: Color(hex: "#F59E0B")) {
                // Budget action
            }
            
            QuickActionButton(icon: "square.and.arrow.down", title: "导入", color: Color(hex: "#22B573")) {
                // Import action
            }
        }
    }
    
    // MARK: - Bill List Section
    
    private var billListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if groupedBills.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("暂无账单")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button {
                        showingQuickAdd = true
                    } label: {
                        Text("记一笔")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color(.systemBackground))
                .cornerRadius(16)
            } else {
                ForEach(groupedBills, id: \.date) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(group.date.relativeDescription)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("-\(group.bills.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }.currencyFormatted)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 0) {
                            ForEach(group.bills) { bill in
                                BillRowView(bill: bill)
                                
                                if bill.id != group.bills.last?.id {
                                    Divider()
                                        .padding(.leading, 56)
                                }
                            }
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func getMonthRange(_ date: Date) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start)!
        return (start, end)
    }
    
    private func saveBill(_ bill: Bill) {
        guard let ledger = currentLedger else { return }
        if ledger.bills == nil {
            ledger.bills = []
        }
        ledger.bills?.append(bill)
        try? modelContext.save()
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Ledger.self, Bill.self, Category.self], inMemory: true)
}