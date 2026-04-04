import SwiftUI
import SwiftData

struct BillEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let ledger: Ledger
    let bill: Bill?
    let preSelectedType: BillType
    let modelContext: ModelContext
    let onSaved: () -> Void

    @State private var amount: String = ""
    @State private var selectedType: BillType
    @State private var selectedCategory: Category?
    @State private var note: String = ""
    @State private var date: Date = Date()

    private var categories: [Category] {
        ledger.categories?.filter { $0.type == selectedType } ?? []
    }

    init(ledger: Ledger, bill: Bill?, preSelectedType: BillType, modelContext: ModelContext, onSaved: @escaping () -> Void) {
        self.ledger = ledger
        self.bill = bill
        self.preSelectedType = preSelectedType
        self.modelContext = modelContext
        self.onSaved = onSaved

        _selectedType = State(initialValue: bill?.type ?? preSelectedType)

        if let bill = bill {
            _amount = State(initialValue: String(format: "%.2f", bill.amount))
            _note = State(initialValue: bill.note ?? "")
            _date = State(initialValue: bill.date)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("金额") {
                    HStack {
                        Text("¥")
                            .font(.title)
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $amount)
                            .font(.system(size: 32, weight: .bold))
                            .keyboardType(.decimalPad)
                    }
                    .padding(.vertical, 8)
                }

                Section("类型") {
                    Picker("类型", selection: $selectedType) {
                        ForEach(BillType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedType) { _, _ in
                        selectedCategory = categories.first
                    }
                }

                Section("分类") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(categories) { category in
                            CategoryButton(
                                category: category,
                                isSelected: selectedCategory?.id == category.id
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                }

                Section("日期") {
                    DatePicker("日期", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }

                Section("备注") {
                    TextField("添加备注（可选）", text: $note, axis: .vertical)
                        .lineLimit(3...5)
                }
            }
            .navigationTitle(bill == nil ? "记账" : "编辑账单")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { saveBill() }
                        .disabled(!isValid)
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let bill = bill {
                    selectedCategory = categories.first { $0.name == bill.categoryName }
                } else if selectedCategory == nil {
                    selectedCategory = categories.first
                }
            }
        }
    }

    private var isValid: Bool {
        guard let amountValue = Double(amount), amountValue > 0 else { return false }
        return selectedCategory != nil
    }

    private func saveBill() {
        guard let amountValue = Double(amount),
              let category = selectedCategory else { return }

        let billService = BillService(billRepository: BillRepository(modelContext: modelContext))

        do {
            if let existingBill = bill {
                try billService.updateBill(
                    existingBill,
                    amount: amountValue,
                    type: selectedType,
                    categoryName: category.name,
                    categoryIcon: category.icon,
                    categoryColorHex: category.colorHex,
                    note: note.isEmpty ? nil : note,
                    date: date
                )
            } else {
                try billService.createBill(
                    amount: amountValue,
                    type: selectedType,
                    categoryName: category.name,
                    categoryIcon: category.icon,
                    categoryColorHex: category.colorHex,
                    note: note.isEmpty ? nil : note,
                    date: date,
                    ledger: ledger
                )
            }
            onSaved()
            dismiss()
        } catch {
            print("保存账单失败: \(error)")
        }
    }
}

// MARK: - CategoryButton

struct CategoryButton: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(Color(hex: category.colorHex).opacity(isSelected ? 0.3 : 0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: category.icon)
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: category.colorHex))
                }
                .overlay(
                    Circle()
                        .strokeBorder(isSelected ? Color(hex: category.colorHex) : Color.clear, lineWidth: 2)
                )

                Text(category.name)
                    .font(.caption2)
                    .foregroundColor(isSelected ? AppColors.textPrimary : AppColors.textSecondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let container = try! ModelContainer(for: Ledger.self, Bill.self, Category.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let ctx = container.mainContext
    BillEditorView(
        ledger: Ledger(name: "测试账本"),
        bill: nil,
        preSelectedType: .expense,
        modelContext: ctx
    ) {}
    .modelContainer(container)
}
