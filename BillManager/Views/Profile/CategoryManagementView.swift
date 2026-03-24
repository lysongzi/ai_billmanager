import SwiftUI
import SwiftData

struct CategoryManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var ledgers: [Ledger]
    @Query private var categories: [Category]
    
    @State private var showingCategoryEditor = false
    @State private var editingCategory: Category?
    @State private var selectedType: BillType = .expense
    
    var currentLedger: Ledger? {
        if let lastSelectedId = UserDefaults.standard.string(forKey: "lastSelectedLedgerId"),
           let uuid = UUID(uuidString: lastSelectedId) {
            return ledgers.first { $0.id == uuid }
        }
        return ledgers.first
    }
    
    var ledgerCategories: [Category] {
        categories.filter { $0.ledger?.id == currentLedger?.id }
    }
    
    var expenseCategories: [Category] {
        ledgerCategories.filter { $0.type == .expense }
    }
    
    var incomeCategories: [Category] {
        ledgerCategories.filter { $0.type == .income }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("类型", selection: $selectedType) {
                        Text("支出").tag(BillType.expense)
                        Text("收入").tag(BillType.income)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("分类列表") {
                    let displayCategories = selectedType == .expense ? expenseCategories : incomeCategories
                    
                    if displayCategories.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "square.grid.2x2")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("暂无分类")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Button {
                                editingCategory = nil
                                showingCategoryEditor = true
                            } label: {
                                Text("添加分类")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                    } else {
                        ForEach(displayCategories) { category in
                            CategoryRowView(category: category) {
                                editingCategory = category
                                showingCategoryEditor = true
                            }
                        }
                        .onDelete(perform: deleteCategories)
                    }
                }
            }
            .navigationTitle("分类管理")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        editingCategory = nil
                        showingCategoryEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCategoryEditor) {
                CategoryEditorView(category: editingCategory, type: selectedType, ledger: currentLedger) { name, icon, colorHex in
                    saveCategory(name: name, icon: icon, colorHex: colorHex)
                }
            }
        }
    }
    
    private func deleteCategories(at offsets: IndexSet) {
        let displayCategories = selectedType == .expense ? expenseCategories : incomeCategories
        for index in offsets {
            let category = displayCategories[index]
            modelContext.delete(category)
        }
        try? modelContext.save()
    }
    
    private func saveCategory(name: String, icon: String, colorHex: String) {
        if let category = editingCategory {
            category.name = name
            category.icon = icon
            category.colorHex = colorHex
        } else {
            let newCategory = Category(name: name, icon: icon, colorHex: colorHex, type: selectedType)
            newCategory.ledger = currentLedger
            modelContext.insert(newCategory)
        }
        try? modelContext.save()
    }
}

struct CategoryRowView: View {
    let category: Category
    let onEdit: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: category.colorHex).opacity(0.2))
                    .frame(width: 36, height: 36)
                Image(systemName: category.icon)
                    .foregroundColor(Color(hex: category.colorHex))
            }
            
            Text(category.name)
                .font(.body)
            
            Spacer()
            
            Button {
                onEdit()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct CategoryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let category: Category?
    let type: BillType
    let ledger: Ledger?
    let onSave: (String, String, String) -> Void
    
    @State private var name: String
    @State private var selectedIcon: String
    @State private var selectedColor: String
    
    private let icons = [
        "fork.knife", "car.fill", "bag.fill", "gamecontroller.fill", "house.fill",
        "cross.fill", "phone.fill", "ellipsis.circle.fill", "banknote.fill", "gift.fill",
        "chart.line.uptrend.xyaxis", "plus.circle.fill", "airplane", "cart.fill", "book.fill",
        "heart.fill", "star.fill", "graduationcap.fill", "briefcase.fill", "airplane"
    ]
    
    private let colors = [
        "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7",
        "#DDA0DD", "#98D8C8", "#2ECC71", "#3498DB", "#9B59B6",
        "#F6C744", "#E74C3C"
    ]
    
    init(category: Category?, type: BillType, ledger: Ledger?, onSave: @escaping (String, String, String) -> Void) {
        self.category = category
        self.type = type
        self.ledger = ledger
        self.onSave = onSave
        _name = State(initialValue: category?.name ?? "")
        _selectedIcon = State(initialValue: category?.icon ?? "fork.knife")
        _selectedColor = State(initialValue: category?.colorHex ?? "#FF6B6B")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("分类名称") {
                    TextField("请输入分类名称", text: $name)
                }
                
                Section("选择图标") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(selectedIcon == icon ? Color(hex: selectedColor).opacity(0.2) : Color.gray.opacity(0.1))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: icon)
                                        .foregroundColor(selectedIcon == icon ? Color(hex: selectedColor) : .secondary)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("选择颜色") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Button {
                                selectedColor = color
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: color))
                                        .frame(width: 36, height: 36)
                                    if selectedColor == color {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.white)
                                            .font(.headline)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("预览") {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color(hex: selectedColor).opacity(0.2))
                                .frame(width: 40, height: 40)
                            Image(systemName: selectedIcon)
                                .foregroundColor(Color(hex: selectedColor))
                        }
                        
                        Text(name.isEmpty ? "分类名称" : name)
                            .foregroundColor(name.isEmpty ? .secondary : .primary)
                        
                        Spacer()
                        
                        Text(type == .expense ? "支出" : "收入")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(category == nil ? "新建分类" : "编辑分类")
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
    CategoryManagementView()
        .modelContainer(for: [Ledger.self, Bill.self, Category.self], inMemory: true)
}