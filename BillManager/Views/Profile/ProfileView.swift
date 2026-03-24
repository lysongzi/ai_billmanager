import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var ledgers: [Ledger]
    @Query private var tags: [Tag]
    @AppStorage("defaultCurrency") private var defaultCurrency: String = "CNY"
    @AppStorage("dateFormat") private var dateFormat: String = "yyyy-MM-dd"
    @AppStorage("reminderEnabled") private var reminderEnabled: Bool = false
    
    @State private var showingLedgerManager = false
    @State private var showingCategoryManagement = false
    @State private var showingTagManagement = false
    @State private var showingAbout = false
    
    var currentLedger: Ledger? {
        if let lastSelectedId = UserDefaults.standard.string(forKey: "lastSelectedLedgerId"),
           let uuid = UUID(uuidString: lastSelectedId) {
            return ledgers.first { $0.id == uuid }
        }
        return ledgers.first
    }
    
    var ledgerTagsCount: Int {
        tags.filter { $0.ledger?.id == currentLedger?.id }.count
    }
    
    var body: some View {
        NavigationStack {
            List {
                // 当前账本信息
                Section {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: currentLedger?.colorHex ?? "#007AFF").opacity(0.2))
                                .frame(width: 60, height: 60)
                            Image(systemName: currentLedger?.icon ?? "book.fill")
                                .font(.title2)
                                .foregroundColor(Color(hex: currentLedger?.colorHex ?? "#007AFF"))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("当前账本")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(currentLedger?.name ?? "未选择")
                                .font(.headline)
                            Text("\(currentLedger?.bills?.count ?? 0) 笔账单")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    
                    Button {
                        showingLedgerManager = true
                    } label: {
                        Label("管理账本", systemImage: "folder.fill")
                    }
                } header: {
                    Text("账本")
                }
                
                // 管理
                Section("管理") {
                    Button {
                        showingCategoryManagement = true
                    } label: {
                        Label("分类管理", systemImage: "square.grid.2x2")
                    }
                    
                    Button {
                        showingTagManagement = true
                    } label: {
                        HStack {
                            Label("标签管理", systemImage: "tag")
                            Spacer()
                            Text("\(ledgerTagsCount) 个标签")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // 设置
                Section("设置") {
                    Picker(selection: $defaultCurrency) {
                        Text("人民币 (CNY)").tag("CNY")
                        Text("美元 (USD)").tag("USD")
                        Text("欧元 (EUR)").tag("EUR")
                    } label: {
                        Label("货币", systemImage: "dollarsign.circle")
                    }
                    
                    Picker(selection: $dateFormat) {
                        Text("yyyy-MM-dd").tag("yyyy-MM-dd")
                        Text("yyyy/MM/dd").tag("yyyy/MM/dd")
                        Text("MM/dd").tag("MM/dd")
                    } label: {
                        Label("日期格式", systemImage: "calendar")
                    }
                    
                    Toggle(isOn: $reminderEnabled) {
                        Label("定时提醒", systemImage: "bell")
                    }
                }
                
                // 数据
                Section("数据") {
                    NavigationLink {
                        DataExportView()
                    } label: {
                        Label("导出数据", systemImage: "square.and.arrow.up")
                    }
                }
                
                // 关于
                Section("关于") {
                    HStack {
                        Label("版本", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Button {
                        showingAbout = true
                    } label: {
                        Label("关于", systemImage: "questionmark.circle")
                    }
                }
            }
            .navigationTitle("我的")
            .sheet(isPresented: $showingLedgerManager) {
                LedgerListView()
            }
            .sheet(isPresented: $showingTagManagement) {
                TagManagementView()
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
    }
}

struct DataExportView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var ledgers: [Ledger]
    @AppStorage("dateFormat") private var dateFormat: String = "yyyy-MM-dd"
    
    var currentLedger: Ledger? {
        if let lastSelectedId = UserDefaults.standard.string(forKey: "lastSelectedLedgerId"),
           let uuid = UUID(uuidString: lastSelectedId) {
            return ledgers.first { $0.id == uuid }
        }
        return ledgers.first
    }
    
    var body: some View {
        List {
            Section {
                if let ledger = currentLedger,
                   let bills = ledger.bills, !bills.isEmpty {
                    HStack {
                        Text("账单数量")
                        Spacer()
                        Text("\(bills.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("时间范围")
                        Spacer()
                        Text("\(bills.min(by: { $0.date < $1.date })?.date.formatted() ?? "N/A") - \(bills.max(by: { $0.date < $1.date })?.date.formatted() ?? "N/A")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("暂无数据")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("数据概览")
            }
            
            Section {
                Button {
                    exportData()
                } label: {
                    Label("导出为 CSV", systemImage: "doc.text")
                }
                .disabled(currentLedger?.bills?.isEmpty ?? true)
            } header: {
                Text("导出")
            }
        }
        .navigationTitle("数据导出")
        .navigationBarTitleDisplayMode(.inline)
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
        } catch {
            print("导出失败: \(error)")
        }
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [Ledger.self, Bill.self, Category.self, Tag.self], inMemory: true)
}