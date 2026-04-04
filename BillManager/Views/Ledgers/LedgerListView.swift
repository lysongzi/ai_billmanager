import SwiftUI
import SwiftData

struct LedgerListView: View {
    @Environment(\.modelContext) private var modelContext

    @State var viewModel: LedgerListViewModel
    @State private var showingLedgerEditor = false
    @State private var editingLedger: Ledger?
    @State private var showingDeleteAlert = false
    @State private var ledgerToDelete: Ledger?

    var body: some View {
        VStack(spacing: 0) {
            CustomNavBar(
                title: "账本",
                rightContent: {
                    NavBarButton(icon: "plus", color: AppColors.primary) {
                        editingLedger = nil
                        showingLedgerEditor = true
                    }
                }
            )

            if viewModel.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(viewModel.activeLedgers) { ledger in
                            NavigationLink(value: ledger) {
                                LedgerCardView(
                                    ledger: ledger,
                                    onEdit: { editingLedger = ledger },
                                    onArchive: {
                                        Task { await viewModel.archiveLedger(ledger) }
                                    },
                                    onDelete: { confirmDelete(ledger) }
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        if !viewModel.archivedLedgers.isEmpty {
                            archivedSection
                        }

                        addLedgerButton
                    }
                    .padding()
                }
            }
        }
        .background(AppColors.background)
        .navigationDestination(for: Ledger.self) { selectedLedger in
            BillListView(ledger: selectedLedger)
        }
        .sheet(isPresented: $showingLedgerEditor) {
            LedgerEditorView(ledger: editingLedger) { name, icon, colorHex in
                if let ledger = editingLedger {
                    Task { await viewModel.updateLedger(ledger, name: name, icon: icon, colorHex: colorHex) }
                } else {
                    Task { await viewModel.createLedger(name: name, icon: icon, colorHex: colorHex) }
                }
            }
        }
        .alert("确认删除", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                if let ledger = ledgerToDelete {
                    Task { await viewModel.deleteLedger(ledger) }
                }
            }
        } message: {
            Text("删除账本将同时删除所有相关账单，此操作不可恢复。")
        }
        .task {
            await viewModel.loadLedgers()
        }
    }

    private var archivedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "archivebox.fill")
                    .font(.system(size: 14))
                Text("已归档账本")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(AppColors.textTertiary)
            .padding(.top, 8)

            ForEach(viewModel.archivedLedgers) { ledger in
                ArchivedLedgerRow(
                    ledger: ledger,
                    onRestore: { Task { await viewModel.restoreLedger(ledger) } },
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
            .foregroundColor(AppColors.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 40)
                    .strokeBorder(AppColors.primary.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [8]))
            )
        }
    }

    private func confirmDelete(_ ledger: Ledger) {
        ledgerToDelete = ledger
        showingDeleteAlert = true
    }
}

// MARK: - LedgerCardView

struct LedgerCardView: View {
    let ledger: Ledger
    let onEdit: () -> Void
    let onArchive: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.spacing5) {
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
                        .font(AppTypography.h3)
                        .foregroundColor(AppColors.textPrimary)
                    Text("\(ledger.bills?.count ?? 0) 笔账单")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textTertiary)
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
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 44, height: 44)
                }
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("收入")
                        .font(AppTypography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textTertiary)
                    Text(ledger.totalIncome.currencyFormatted)
                        .font(AppTypography.amountSmall)
                        .foregroundColor(AppColors.income)
                }

                Spacer()

                VStack(alignment: .center, spacing: 4) {
                    Text("支出")
                        .font(AppTypography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textTertiary)
                    Text(ledger.totalExpense.currencyFormatted)
                        .font(AppTypography.amountSmall)
                        .foregroundColor(AppColors.expense)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("结余")
                        .font(AppTypography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textTertiary)
                    Text(ledger.balance.currencyFormatted)
                        .font(AppTypography.amountSmall)
                        .fontWeight(.bold)
                        .foregroundColor(ledger.balance >= 0 ? AppColors.textPrimary : AppColors.expense)
                }
            }
        }
        .padding(AppSpacing.spacing6)
        .background(AppColors.cardBackground)
        .cornerRadius(AppCornerRadius.extraLarge)
        .shadowLight()
    }
}

// MARK: - ArchivedLedgerRow

struct ArchivedLedgerRow: View {
    let ledger: Ledger
    let onRestore: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Image(systemName: ledger.icon)
                .foregroundColor(Color(hex: ledger.colorHex))

            Text(ledger.name)
                .foregroundColor(AppColors.textSecondary)

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
                .fill(AppColors.backgroundAlt)
        )
    }
}

// MARK: - LedgerEditorView

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
                                            .fill(selectedIcon == icon ? AppColors.primary.opacity(0.2) : Color.gray.opacity(0.1))
                                    )
                                    .foregroundColor(selectedIcon == icon ? AppColors.primary : AppColors.textPrimary)
                            }
                            .buttonStyle(.plain)
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
                                            .strokeBorder(selectedColor == color ? AppColors.textPrimary : Color.clear, lineWidth: 3)
                                    )
                            }
                            .buttonStyle(.plain)
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
    let container = try! ModelContainer(for: Ledger.self, Bill.self, Category.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let ctx = container.mainContext
    let ledgerRepo = LedgerRepository(modelContext: ctx)
    let categoryRepo = CategoryRepository(modelContext: ctx)
    let ledgerService = LedgerService(ledgerRepository: ledgerRepo, categoryRepository: categoryRepo)
    return NavigationStack {
        LedgerListView(viewModel: LedgerListViewModel(ledgerService: ledgerService))
    }
    .modelContainer(container)
}
