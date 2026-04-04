import SwiftUI
import SwiftData

struct BillListView: View {
    @Bindable var ledger: Ledger
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: BillListViewModel?
    @State private var showingBillEditor = false
    @State private var editingBill: Bill?
    @State private var selectedBillType: BillType = .expense
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            if let vm = viewModel {
                summaryHeader(vm: vm)

                if vm.bills.isEmpty && !vm.isLoading {
                    emptyState
                } else {
                    billsList(vm: vm)
                }
            } else {
                Spacer()
                ProgressView()
                Spacer()
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
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingBillEditor) {
            BillEditorView(
                ledger: ledger,
                bill: editingBill,
                preSelectedType: selectedBillType,
                modelContext: modelContext
            ) {
                Task { await viewModel?.loadBills() }
            }
        }
        .searchable(text: $searchText, prompt: "搜索账单")
        .onChange(of: searchText) { _, keyword in
            Task { await viewModel?.searchBills(keyword: keyword) }
        }
        .task {
            // Build ViewModel from modelContext
            if viewModel == nil {
                let billRepo = BillRepository(modelContext: modelContext)
                let billService = BillService(billRepository: billRepo)
                let vm = BillListViewModel(billService: billService)
                vm.selectedLedger = ledger
                viewModel = vm
            }
            await viewModel?.loadBills()
        }
    }

    private func summaryHeader(vm: BillListViewModel) -> some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("收入")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(vm.totalIncome.currencyFormatted)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.income)
                }

                Spacer()

                VStack(alignment: .center, spacing: 4) {
                    Text("支出")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(vm.totalExpense.currencyFormatted)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.expense)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("结余")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(vm.balance.currencyFormatted)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(vm.balance >= 0 ? AppColors.income : AppColors.expense)
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

    private func billsList(vm: BillListViewModel) -> some View {
        List {
            ForEach(vm.groupedBills, id: \.date) { group in
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
                                    Task { await vm.deleteBill(bill) }
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

    private func dailyTotal(for bills: [Bill]) -> Double {
        let income = bills.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let expense = bills.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        return income - expense
    }
}

// MARK: - BillRowView

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
                .foregroundColor(bill.type == .expense ? AppColors.expense : AppColors.income)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let container = try! ModelContainer(for: Ledger.self, Bill.self, Category.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let ctx = container.mainContext
    NavigationStack {
        BillListView(ledger: Ledger(name: "测试账本"))
    }
    .modelContainer(container)
}
