import SwiftUI
import SwiftData

struct BillEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let ledger: Ledger
    let bill: Bill?
    let preSelectedType: BillType
    let onSave: (Bill) -> Void

    @State private var amount: String = ""
    @State private var selectedType: BillType
    @State private var selectedCategory: Category?
    @State private var note: String = ""
    @State private var date: Date = Date()

    private var categories: [Category] {
        ledger.categories?.filter { $0.type == selectedType } ?? []
    }

    init(ledger: Ledger, bill: Bill?, preSelectedType: BillType, onSave: @escaping (Bill) -> Void) {
        self.ledger = ledger
        self.bill = bill
        self.preSelectedType = preSelectedType
        self.onSave = onSave

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

        let newBill = Bill(
            id: bill?.id ?? UUID(),
            amount: amountValue,
            type: selectedType,
            categoryName: category.name,
            categoryIcon: category.icon,
            categoryColorHex: category.colorHex,
            note: note.isEmpty ? nil : note,
            date: date,
            createdAt: bill?.createdAt ?? Date(),
            updatedAt: Date()
        )

        onSave(newBill)
        dismiss()
    }
}

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
                    .foregroundColor(isSelected ? .primary : .secondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
}

struct QuickAddView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let ledger: Ledger
    let onSave: (Bill) -> Void

    @State private var amount: String = ""
    @State private var selectedType: BillType = .expense
    @State private var selectedCategory: Category?

    private var categories: [Category] {
        ledger.categories?.filter { $0.type == selectedType } ?? []
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                amountDisplay

                typeSelector

                categoryGrid

                Spacer()

                saveButton
            }
            .navigationTitle("快捷记账")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .onAppear {
                selectedCategory = categories.first
            }
        }
        .presentationDetents([.medium])
    }

    private var amountDisplay: some View {
        VStack {
            Text(selectedType == .expense ? "支出" : "收入")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("¥")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(.secondary)

                TextField("0", text: $amount)
                    .font(.system(size: 56, weight: .bold))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 24)
    }

    private var typeSelector: some View {
        HStack(spacing: 20) {
            ForEach(BillType.allCases, id: \.self) { type in
                Button {
                    selectedType = type
                    selectedCategory = categories.first
                } label: {
                    HStack {
                        Image(systemName: type.icon)
                        Text(type.displayName)
                    }
                    .font(.headline)
                    .foregroundColor(selectedType == type ? (type == .expense ? .white : .white) : .primary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(selectedType == type ? (type == .expense ? Color.red : Color.green) : Color.gray.opacity(0.15))
                    )
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 16)
    }

    private var categoryGrid: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                ForEach(categories) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: category.colorHex).opacity(selectedCategory?.id == category.id ? 0.3 : 0.15))
                                    .frame(width: 50, height: 50)
                                Image(systemName: category.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(hex: category.colorHex))
                            }

                            Text(category.name)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    private var saveButton: some View {
        Button {
            saveBill()
        } label: {
            Text("保存")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isValid ? Color.accentColor : Color.gray)
                .cornerRadius(12)
        }
        .disabled(!isValid)
        .padding()
    }

    private var isValid: Bool {
        guard let amountValue = Double(amount), amountValue > 0 else { return false }
        return selectedCategory != nil
    }

    private func saveBill() {
        guard let amountValue = Double(amount),
              let category = selectedCategory else { return }

        let bill = Bill(
            amount: amountValue,
            type: selectedType,
            categoryName: category.name,
            categoryIcon: category.icon,
            categoryColorHex: category.colorHex,
            date: Date()
        )

        onSave(bill)
        dismiss()
    }
}

#Preview {
    BillEditorView(
        ledger: Ledger(name: "测试账本"),
        bill: nil,
        preSelectedType: .expense
    ) { _ in }
    .modelContainer(for: [Ledger.self, Bill.self, Category.self], inMemory: true)
}