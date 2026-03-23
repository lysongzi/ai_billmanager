import SwiftUI
import SwiftData

struct BillListView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var ledger: Ledger

    @State private var showingBillEditor = false
    @State private var editingBill: Bill?
    @State private var showingQuickAdd = false
    @State private var selectedBillType: BillType = .expense
    @State private var searchText = ""

    var bills: [Bill] {
        let allBills = ledger.bills ?? []
        if searchText.isEmpty {
            return allBills.sorted { $0.date > $1.date }
        }
        return allBills.filter {
            $0.categoryName.localizedCaseInsensitiveContains(searchText) ||
            ($0.note?.localizedCaseInsensitiveContains(searchText) ?? false)
        }.sorted { $0.date > $1.date }
    }

    var groupedBills: [(date: Date, bills: [Bill])] {
        bills.groupedByDate()
    }

    var body: some View {
        VStack(spacing: 0) {
            summaryHeader

            if bills.isEmpty {
                emptyState
            } else {
                billsList
            }
        }
        .navigationTitle(ledger.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        selectedBillType = .expense
                        editingBill = nil
                        showingBillEditor = true
                    } label: {
                        Label("记支出", systemImage: "arrow.up.circle")
                    }
                    Button {
                        selectedBillType = .income
                        editingBill = nil
                        showingBillEditor = true
                    } label: {
                        Label("记收入", systemImage: "arrow.down.circle")
                    }
                    Divider()
                    Button {
                        showingQuickAdd = true
                    } label: {
                        Label("快捷记账", systemImage: "bolt.fill")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingBillEditor) {
            BillEditorView(
                ledger: ledger,
                bill: editingBill,
                preSelectedType: selectedBillType
            ) { bill in
                saveBill(bill)
            }
        }
        .sheet(isPresented: $showingQuickAdd) {
            QuickAddView(ledger: ledger) { bill in
                saveBill(bill)
            }
        }
        .searchable(text: $searchText, prompt: "搜索账单")
    }

    private var summaryHeader: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("收入")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(totalIncome.currencyFormatted)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }

                Spacer()

                VStack(alignment: .center, spacing: 4) {
                    Text("支出")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(totalExpense.currencyFormatted)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("结余")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(balance.currencyFormatted)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(balance >= 0 ? .green : .red)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("暂无账单")
                .font(.title3)
                .foregroundColor(.secondary)
            Text("点击右上角添加第一笔账单")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    private var billsList: some View {
        List {
            ForEach(groupedBills, id: \.date) { group in
                Section {
                    ForEach(group.bills) { bill in
                        BillRowView(bill: bill)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingBill = bill
                                showingBillEditor = true
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteBill(bill)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                    }
                } header: {
                    HStack {
                        Text(group.date.relativeDescription)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text(dailyTotal(for: group.bills).currencyFormatted)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var totalIncome: Double {
        bills.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    private var totalExpense: Double {
        bills.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    private var balance: Double {
        totalIncome - totalExpense
    }

    private func dailyTotal(for bills: [Bill]) -> Double {
        let income = bills.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let expense = bills.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        return income - expense
    }

    private func saveBill(_ bill: Bill) {
        if let editingBill = editingBill {
            editingBill.amount = bill.amount
            editingBill.type = bill.type
            editingBill.categoryName = bill.categoryName
            editingBill.categoryIcon = bill.categoryIcon
            editingBill.categoryColorHex = bill.categoryColorHex
            editingBill.note = bill.note
            editingBill.date = bill.date
            editingBill.updatedAt = Date()
        } else {
            if ledger.bills == nil {
                ledger.bills = []
            }
            ledger.bills?.append(bill)
        }
        try? modelContext.save()
    }

    private func deleteBill(_ bill: Bill) {
        modelContext.delete(bill)
        try? modelContext.save()
    }
}

struct BillRowView: View {
    let bill: Bill

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: bill.categoryColorHex).opacity(0.2))
                    .frame(width: 44, height: 44)
                Image(systemName: bill.categoryIcon)
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: bill.categoryColorHex))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(bill.categoryName)
                    .font(.body)
                    .fontWeight(.medium)
                if let note = bill.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text((bill.type == .expense ? "-" : "+") + bill.amount.currencyFormatted)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(bill.type == .expense ? .red : .green)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        BillListView(ledger: Ledger(name: "测试账本"))
    }
    .modelContainer(for: [Ledger.self, Bill.self, Category.self], inMemory: true)
}