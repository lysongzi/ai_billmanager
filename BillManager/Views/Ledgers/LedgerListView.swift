import SwiftUI
import SwiftData

struct LedgerListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Ledger.createdAt, order: .reverse) private var ledgers: [Ledger]
    @Query private var allBills: [Bill]

    @State private var selectedLedger: Ledger?
    @State private var showingLedgerEditor = false
    @State private var editingLedger: Ledger?
    @State private var showingDeleteAlert = false
    @State private var ledgerToDelete: Ledger?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                
                ForEach(ledgers) { ledger in
                    if !ledger.isArchived {
                        NavigationLink(destination: BillListView(ledger: ledger)) {
                            LedgerCardView(
                                ledger: ledger,
                                onEdit: { editingLedger = ledger },
                                onArchive: { archiveLedger(ledger) },
                                onDelete: { confirmDelete(ledger) }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                if !ledgers.filter({ $0.isArchived }).isEmpty {
                    archivedSection
                }

                addLedgerButton
            }
            .padding()
        }
        .background(Color(red: 250/255, green: 250/255, blue: 249/255))
        .sheet(isPresented: $showingLedgerEditor) {
            LedgerEditorView(ledger: editingLedger) { name, icon, colorHex in
                saveLedger(name: name, icon: icon, colorHex: colorHex)
            }
        }
        .alert("确认删除", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                if let ledger = ledgerToDelete {
                    deleteLedger(ledger)
                }
            }
        } message: {
            Text("删除账本将同时删除所有相关账单，此操作不可恢复。")
        }
    }
    
    private var headerSection: some View {
        HStack {
            Text("账本")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color(red: 28/255, green: 25/255, blue: 23/255))
            Spacer()
            
            Button {
                editingLedger = nil
                showingLedgerEditor = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color(red: 245/255, green: 158/255, blue: 11/255))
                    )
            }
        }
        .padding(.top, 60)
    }
    
    private var archivedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "archivebox.fill")
                    .font(.system(size: 14))
                Text("已归档账本")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(Color(red: 168/255, green: 162/255, blue: 158/255))
            .padding(.top, 8)
            
            ForEach(ledgers.filter { $0.isArchived }) { ledger in
                ArchivedLedgerRow(
                    ledger: ledger,
                    onRestore: { restoreLedger(ledger) },
                    onDelete: { confirmDelete(ledger) }
                )
            }
        }
    }

    private var addLedgerButton: some View {
        Button {
            editingLedger = nil
            showingLedgerEditor = true
        } label: {
            HStack {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                Text("新建账本")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(Color(red: 245/255, green: 158/255, blue: 11/255))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 40)
                    .strokeBorder(Color(red: 245/255, green: 158/255, blue: 11/255).opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [8]))
            )
        }
    }

    private func saveLedger(name: String, icon: String, colorHex: String) {
        if let ledger = editingLedger {
            ledger.name = name
            ledger.icon = icon
            ledger.colorHex = colorHex
        } else {
            let newLedger = Ledger(name: name, icon: icon, colorHex: colorHex)
            newLedger.categories = createDefaultCategories()
            modelContext.insert(newLedger)
        }
        try? modelContext.save()
    }

    private func archiveLedger(_ ledger: Ledger) {
        ledger.isArchived = true
        try? modelContext.save()
    }

    private func restoreLedger(_ ledger: Ledger) {
        ledger.isArchived = false
        try? modelContext.save()
    }

    private func confirmDelete(_ ledger: Ledger) {
        ledgerToDelete = ledger
        showingDeleteAlert = true
    }

    private func deleteLedger(_ ledger: Ledger) {
        modelContext.delete(ledger)
        try? modelContext.save()
    }

    private func createDefaultCategories() -> [Category] {
        let expenseData = [
            ("餐饮", "fork.knife", "#FF6B6B"),
            ("交通", "car.fill", "#4ECDC4"),
            ("购物", "bag.fill", "#45B7D1"),
            ("娱乐", "gamecontroller.fill", "#96CEB4"),
            ("居住", "house.fill", "#FFEAA7"),
            ("医疗", "cross.fill", "#DDA0DD"),
            ("通讯", "phone.fill", "#98D8C8"),
            ("其他", "ellipsis.circle.fill", "#B8B8B8")
        ]

        let incomeData = [
            ("工资", "banknote.fill", "#2ECC71"),
            ("奖金", "gift.fill", "#27AE60"),
            ("投资收益", "chart.line.uptrend.xyaxis", "#3498DB"),
            ("其他收入", "plus.circle.fill", "#9B59B6")
        ]

        var categories: [Category] = []

        for (name, icon, color) in expenseData {
            categories.append(Category(name: name, icon: icon, colorHex: color, type: .expense))
        }

        for (name, icon, color) in incomeData {
            categories.append(Category(name: name, icon: icon, colorHex: color, type: .income))
        }

        return categories
    }
}

struct LedgerCardView: View {
    let ledger: Ledger
    let onEdit: () -> Void
    let onArchive: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color(hex: ledger.colorHex).opacity(0.15))
                        .frame(width: 56, height: 56)
                    Image(systemName: ledger.icon)
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: ledger.colorHex))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(ledger.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(red: 28/255, green: 25/255, blue: 23/255))
                    Text("\(ledger.bills?.count ?? 0) 笔账单")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 168/255, green: 162/255, blue: 158/255))
                }

                Spacer()

                Menu {
                    Button { onEdit() } label: {
                        Label("编辑", systemImage: "pencil")
                    }
                    Button { onArchive() } label: {
                        Label("归档", systemImage: "archivebox")
                    }
                    Divider()
                    Button(role: .destructive) { onDelete() } label: {
                        Label("删除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18))
                        .foregroundColor(Color(red: 120/255, green: 113/255, blue: 108/255))
                        .frame(width: 44, height: 44)
                }
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("收入")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 168/255, green: 162/255, blue: 158/255))
                    Text(ledger.totalIncome.currencyFormatted)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(red: 16/255, green: 185/255, blue: 129/255))
                }

                Spacer()

                VStack(alignment: .center, spacing: 4) {
                    Text("支出")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 168/255, green: 162/255, blue: 158/255))
                    Text(ledger.totalExpense.currencyFormatted)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(red: 244/255, green: 63/255, blue: 94/255))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("结余")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 168/255, green: 162/255, blue: 158/255))
                    Text(ledger.balance.currencyFormatted)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(ledger.balance >= 0 ? Color(red: 28/255, green: 25/255, blue: 23/255) : Color(red: 244/255, green: 63/255, blue: 94/255))
                }
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(40)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

struct ArchivedLedgerRow: View {
    let ledger: Ledger
    let onRestore: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Image(systemName: ledger.icon)
                .foregroundColor(Color(hex: ledger.colorHex))

            Text(ledger.name)
                .foregroundColor(.secondary)

            Spacer()

            Button("恢复") { onRestore() }
                .font(.caption)

            Button(role: .destructive) { onDelete() } label: {
                Image(systemName: "trash")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct LedgerEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let ledger: Ledger?
    let onSave: (String, String, String) -> Void

    @State private var name: String
    @State private var selectedIcon: String
    @State private var selectedColor: String

    private let icons = [
        "book.fill", "creditcard.fill", "banknote.fill", "chart.pie.fill",
        "house.fill", "car.fill", "airplane", "gift.fill", "heart.fill",
        "star.fill", "folder.fill", "briefcase.fill", "graduationcap.fill"
    ]

    private let colors = [
        "#007AFF", "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4",
        "#FFEAA7", "#DDA0DD", "#98D8C8", "#2ECC71", "#3498DB"
    ]

    init(ledger: Ledger?, onSave: @escaping (String, String, String) -> Void) {
        self.ledger = ledger
        self.onSave = onSave
        _name = State(initialValue: ledger?.name ?? "")
        _selectedIcon = State(initialValue: ledger?.icon ?? "book.fill")
        _selectedColor = State(initialValue: ledger?.colorHex ?? "#007AFF")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("账本名称") {
                    TextField("请输入账本名称", text: $name)
                }

                Section("选择图标") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(icons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .frame(width: 50, height: 50)
                                    .background(
                                        Circle()
                                            .fill(selectedIcon == icon ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
                                    )
                                    .foregroundColor(selectedIcon == icon ? .accentColor : .primary)
                            }
                        }
                    }
                }

                Section("选择颜色") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                        ForEach(colors, id: \.self) { color in
                            Button {
                                selectedColor = color
                            } label: {
                                Circle()
                                    .fill(Color(hex: color))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(selectedColor == color ? Color.primary : Color.clear, lineWidth: 3)
                                    )
                            }
                        }
                    }
                }

                Section("预览") {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color(hex: selectedColor).opacity(0.2))
                                .frame(width: 60, height: 60)
                            Image(systemName: selectedIcon)
                                .font(.title)
                                .foregroundColor(Color(hex: selectedColor))
                        }

                        Text(name.isEmpty ? "账本名称" : name)
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                }
            }
            .navigationTitle(ledger == nil ? "新建账本" : "编辑账本")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(name, selectedIcon, selectedColor)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    LedgerListView()
        .modelContainer(for: [Ledger.self, Bill.self, Category.self], inMemory: true)
}