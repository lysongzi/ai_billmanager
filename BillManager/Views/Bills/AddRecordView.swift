import SwiftUI
import SwiftData

struct AddRecordView: View {
    @Environment(\.dismiss) private var dismiss

    @State var viewModel: AddRecordViewModel
    let currentLedger: Ledger?

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        amountSection

                        typeToggleSection

                        categorySection

                        dateTimeSection

                        noteSection
                    }
                    .padding(.horizontal, AppSpacing.spacing5)
                    .padding(.top, AppSpacing.spacing5)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("记账")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .foregroundColor(AppColors.textSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        guard let ledger = currentLedger else { return }
                        Task {
                            await viewModel.save(to: ledger)
                        }
                    }
                    .foregroundColor(viewModel.canSave ? AppColors.primary : AppColors.textTertiary)
                    .disabled(!viewModel.canSave)
                }
            }
            .onAppear {
                if let ledger = currentLedger {
                    Task { await viewModel.loadCategories(for: ledger) }
                }
            }
            .onChange(of: viewModel.isSaved) { _, saved in
                if saved { dismiss() }
            }
            .onChange(of: viewModel.selectedType) { _, _ in
                if let ledger = currentLedger {
                    Task { await viewModel.reloadCategories(for: ledger) }
                }
            }
        }
    }

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("金额")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
                .padding(.leading, 8)

            VStack(spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("¥")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)

                    TextField("0.00", text: $viewModel.amount)
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                        .keyboardType(.decimalPad)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(AppSpacing.spacing5)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.extraLarge)
                    .fill(AppColors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.extraLarge)
                    .stroke(AppColors.primary.opacity(0.2), lineWidth: 1)
                    .padding(.top, 1)
            )
        }
    }

    private var typeToggleSection: some View {
        HStack(spacing: 8) {
            ForEach([BillType.income, .expense], id: \.self) { type in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        viewModel.selectedType = type
                    }
                } label: {
                    Text(type.displayName)
                        .font(.system(size: 14, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(viewModel.selectedType == type ? AppColors.textPrimary : AppColors.cardBackground)
                        )
                        .foregroundColor(viewModel.selectedType == type ? .white : AppColors.textSecondary)
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(AppColors.backgroundAlt)
        )
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分类")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
                .padding(.leading, 8)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 16) {
                ForEach(viewModel.categories) { category in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.selectedCategory = category
                        }
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                    .fill(Color(hex: category.colorHex).opacity(0.15))
                                    .frame(width: 52, height: 52)

                                Image(systemName: category.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(hex: category.colorHex))
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                    .stroke(
                                        viewModel.selectedCategory?.id == category.id ? AppColors.textPrimary : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                            .scaleEffect(viewModel.selectedCategory?.id == category.id ? 1.1 : 1.0)

                            Text(category.name)
                                .font(.system(size: 11))
                                .foregroundColor(viewModel.selectedCategory?.id == category.id ? AppColors.textPrimary : AppColors.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(AppSpacing.spacing5)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.extraLarge)
                    .fill(AppColors.cardBackground)
            )
        }
    }

    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("日期与时间")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
                .padding(.leading, 8)

            HStack(spacing: 12) {
                DatePicker("", selection: $viewModel.selectedDate, displayedComponents: .date)
                    .labelsHidden()
                    .padding(.horizontal, AppSpacing.spacing4)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: AppCornerRadius.large)
                            .fill(AppColors.backgroundAlt)
                    )

                DatePicker("", selection: $viewModel.selectedDate, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .padding(.horizontal, AppSpacing.spacing4)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: AppCornerRadius.large)
                            .fill(AppColors.backgroundAlt)
                    )
            }
        }
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("备注")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
                .padding(.leading, 8)

            TextEditor(text: $viewModel.note)
                .font(.system(size: 14))
                .frame(height: 100)
                .padding(AppSpacing.spacing4)
                .background(
                    RoundedRectangle(cornerRadius: AppCornerRadius.extraLarge)
                        .fill(AppColors.cardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.extraLarge)
                        .stroke(Color.black.opacity(0.05), lineWidth: 1)
                )
                .scrollContentBackground(.hidden)
        }
    }
}

#Preview {
    AddRecordView(
        viewModel: AddRecordViewModel(
            billService: BillService(billRepository: BillRepository(modelContext: {
                let container = try! ModelContainer(for: Ledger.self, Bill.self, Category.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
                return container.mainContext
            }())),
            categoryRepository: CategoryRepository(modelContext: {
                let container = try! ModelContainer(for: Ledger.self, Bill.self, Category.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
                return container.mainContext
            }())
        ),
        currentLedger: nil
    )
}
