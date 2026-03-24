import SwiftUI

struct AddRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let ledger: Ledger?
    let onSave: (Bill) -> Void
    
    @State private var amount: String = ""
    @State private var billType: BillType = .expense
    @State private var selectedCategory: Category?
    @State private var note: String = ""
    @State private var date: Date = Date()
    
    private var categories: [Category] {
        ledger?.categories?.filter { $0.type == billType } ?? []
    }
    
    private var canSave: Bool {
        guard let amountVal = Double(amount), amountVal > 0 else { return false }
        return selectedCategory != nil
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(AppColors.background)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        amountSection
                        
                        typeToggleSection
                        
                        categorySection
                        
                        dateTimeSection
                        
                        noteSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
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
                    Button("保存") { saveBill() }
                        .foregroundColor(canSave ? AppColors.primary : AppColors.textTertiary)
                        .disabled(!canSave)
                }
            }
            .onAppear {
                if selectedCategory == nil, let first = categories.first {
                    selectedCategory = first
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
                    
                    TextField("0.00", text: $amount)
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                        .keyboardType(.decimalPad)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.extraLarge)
                    .fill(Color.white)
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
                        billType = type
                        selectedCategory = categories.first
                    }
                } label: {
                    Text(type.displayName)
                        .font(.system(size: 14, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(billType == type ? Color(AppColors.textPrimary) : Color.white)
                        )
                        .foregroundColor(billType == type ? .white : AppColors.textSecondary)
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color(AppColors.backgroundAlt))
        )
    }
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分类")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
                .padding(.leading, 8)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 16) {
                ForEach(categories) { category in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCategory = category
                        }
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                    .fill(Color(category.colorHex).opacity(0.15))
                                    .frame(width: 52, height: 52)
                                
                                Image(systemName: category.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(category.colorHex))
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                    .stroke(
                                        selectedCategory?.id == category.id ? AppColors.textPrimary : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                            .scaleEffect(selectedCategory?.id == category.id ? 1.1 : 1.0)
                            
                            Text(category.name)
                                .font(.system(size: 11))
                                .foregroundColor(selectedCategory?.id == category.id ? AppColors.textPrimary : AppColors.textSecondary)
                        }
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.extraLarge)
                    .fill(Color.white)
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
                DatePicker("", selection: $date, displayedComponents: .date)
                    .labelsHidden()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: AppCornerRadius.large)
                            .fill(Color(AppColors.backgroundAlt))
                    )
                
                DatePicker("", selection: $date, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: AppCornerRadius.large)
                            .fill(Color(AppColors.backgroundAlt))
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
            
            TextEditor(text: $note)
                .font(.system(size: 14))
                .frame(height: 100)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: AppCornerRadius.extraLarge)
                        .fill(Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.extraLarge)
                        .stroke(Color.black.opacity(0.05), lineWidth: 1)
                )
                .scrollContentBackground(.hidden)
        }
    }
    
    private func saveBill() {
        guard let amountVal = Double(amount),
              let category = selectedCategory else { return }
        
        let bill = Bill(
            amount: amountVal,
            type: billType,
            categoryName: category.name,
            categoryIcon: category.icon,
            categoryColorHex: category.colorHex,
            note: note.isEmpty ? nil : note,
            date: date
        )
        
        onSave(bill)
        dismiss()
    }
}

#Preview {
    AddRecordView(ledger: nil) { _ in }
}