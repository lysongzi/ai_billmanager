import SwiftUI
import SwiftData

struct BudgetView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var ledgers: [Ledger]
    @Query private var budgets: [Budget]
    
    @State private var selectedLedger: Ledger?
    @State private var showingBudgetEditor = false
    @State private var editingBudget: Budget?
    
    private var currentLedger: Ledger? {
        if let lastSelectedId = UserDefaults.standard.string(forKey: "lastSelectedLedgerId"),
           let uuid = UUID(uuidString: lastSelectedId) {
            return ledgers.first { $0.id == uuid }
        }
        return ledgers.first
    }
    
    private var currentBudget: Budget? {
        budgets.first { $0.ledger?.id == currentLedger?.id && $0.isEnabled }
    }
    
    private var monthBills: [Bill] {
        guard let ledger = currentLedger else { return [] }
        let calendar = Calendar.current
        let now = Date()
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start)!
        return (ledger.bills ?? []).filter { $0.date >= start && $0.date <= end && $0.type == .expense }
    }
    
    private var totalExpense: Double {
        monthBills.reduce(0) { $0 + $1.amount }
    }
    
    private var budgetProgress: BudgetProgress? {
        guard let budget = currentBudget else { return nil }
        return BudgetProgress(budget: budget, spentAmount: totalExpense)
    }
    
    private var totalIncome: Double {
        guard let ledger = currentLedger else { return 0 }
        let calendar = Calendar.current
        let now = Date()
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start)!
        return (ledger.bills ?? []).filter { $0.date >= start && $0.date <= end && $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    budgetAlertCard
                    
                    budgetDetailCard
                    
                    assetOverviewCard
                    
                    insightCard
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("发现")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        editingBudget = currentBudget
                        showingBudgetEditor = true
                    } label: {
                        Image(systemName: currentBudget == nil ? "plus.circle" : "pencil.circle")
                    }
                }
            }
            .sheet(isPresented: $showingBudgetEditor) {
                BudgetEditorView(budget: editingBudget, ledger: currentLedger) { amount, period in
                    saveBudget(amount: amount, period: period)
                }
            }
        }
    }
    
    // MARK: - Budget Alert Card
    
    private var budgetAlertCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(budgetProgress?.isOverBudget == true ? .red : .orange)
                Text("本月预算")
                    .font(.headline)
                Spacer()
                if let progress = budgetProgress {
                    Text("\(Int(100 - progress.progressPercentage))% 剩余")
                        .font(.subheadline)
                        .foregroundColor(progress.isOverBudget ? .red : .secondary)
                }
            }
            
            if let progress = budgetProgress {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 12)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(progress.isOverBudget ? Color.red : Color.orange)
                            .frame(width: min(geometry.size.width * min(progress.progressPercentage / 100, 1.0), geometry.size.width), height: 12)
                    }
                }
                .frame(height: 12)
            } else {
                Text("点击设置预算")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Budget Detail Card
    
    private var budgetDetailCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("预算详情")
                .font(.headline)
            
            if let progress = budgetProgress {
                VStack(spacing: 12) {
                    BudgetDetailRow(title: "预算金额", value: progress.budget.amount.currencyFormatted)
                    BudgetDetailRow(title: "已花费", value: progress.spentAmount.currencyFormatted, color: .red)
                    BudgetDetailRow(title: "剩余", value: progress.remainingAmount.currencyFormatted, 
                                  color: progress.remainingAmount >= 0 ? .green : .red)
                }
                
                HStack(spacing: 12) {
                    Button {
                        editingBudget = currentBudget
                        showingBudgetEditor = true
                    } label: {
                        Text("修改预算")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(10)
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("暂无预算")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button {
                        showingBudgetEditor = true
                    } label: {
                        Text("设置预算")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Asset Overview Card
    
    private var assetOverviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("资产概览")
                .font(.headline)
            
            VStack(spacing: 12) {
                HStack {
                    Text("总收入")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(totalIncome.currencyFormatted)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("总支出")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(totalExpense.currencyFormatted)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                }
                
                Divider()
                
                HStack {
                    Text("本月结余")
                        .font(.headline)
                    Spacer()
                    Text((totalIncome - totalExpense).currencyFormatted)
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(totalIncome >= totalExpense ? .green : .red)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Insight Card
    
    private var insightCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("发现")
                .font(.headline)
            
            if monthBills.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 30))
                        .foregroundColor(.orange)
                    Text("开始记账以获取洞察")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    InsightRow(icon: "chart.line.uptrend.xyaxis", 
                              title: "支出趋势",
                              description: "本月支出 \(monthBills.count) 笔")
                    
                    if let progress = budgetProgress, progress.isOverBudget {
                        InsightRow(icon: "exclamationmark.triangle.fill",
                                  title: "预算提醒",
                                  description: "本月支出已超预算",
                                  color: .red)
                    }
                    
                    InsightRow(icon: "tag.fill",
                              title: "消费分类",
                              description: "共 \(Array(Set(monthBills.map { $0.categoryName })).count) 个分类")
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Helpers
    
    private func saveBudget(amount: Double, period: Budget.BudgetPeriod) {
        if let existingBudget = currentBudget {
            existingBudget.amount = amount
            existingBudget.period = period
        } else {
            let newBudget = Budget(
                amount: amount,
                period: period,
                ledger: currentLedger
            )
            modelContext.insert(newBudget)
        }
        try? modelContext.save()
    }
}

// MARK: - Subviews

struct BudgetDetailRow: View {
    let title: String
    let value: String
    var color: Color = .primary
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

struct InsightRow: View {
    let icon: String
    let title: String
    let description: String
    var color: Color = .blue
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Budget Editor

struct BudgetEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let budget: Budget?
    let ledger: Ledger?
    let onSave: (Double, Budget.BudgetPeriod) -> Void
    
    @State private var amount: String = ""
    @State private var period: Budget.BudgetPeriod = .monthly
    
    init(budget: Budget?, ledger: Ledger?, onSave: @escaping (Double, Budget.BudgetPeriod) -> Void) {
        self.budget = budget
        self.ledger = ledger
        self.onSave = onSave
        _amount = State(initialValue: budget != nil ? String(format: "%.0f", budget!.amount) : "5000")
        _period = State(initialValue: budget?.period ?? .monthly)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("预算金额") {
                    HStack {
                        Text("¥")
                            .foregroundColor(.secondary)
                        TextField("0", text: $amount)
                            .keyboardType(.numberPad)
                    }
                }
                
                Section("预算周期") {
                    Picker("周期", selection: $period) {
                        ForEach(Budget.BudgetPeriod.allCases, id: \.self) { p in
                            Text(p.displayName).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("快捷设置") {
                    ForEach([2000, 3000, 5000, 10000], id: \.self) { value in
                        Button {
                            amount = String(value)
                        } label: {
                            Text("¥\(value)")
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .navigationTitle(budget == nil ? "设置预算" : "修改预算")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        if let value = Double(amount), value > 0 {
                            onSave(value, period)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    BudgetView()
        .modelContainer(for: [Ledger.self, Bill.self, Category.self, Budget.self], inMemory: true)
}