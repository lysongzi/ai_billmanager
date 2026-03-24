import SwiftUI
import SwiftData

struct TagManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tags: [Tag]
    @Query private var ledgers: [Ledger]
    
    @State private var showingTagEditor = false
    @State private var editingTag: Tag?
    
    var currentLedger: Ledger? {
        if let lastSelectedId = UserDefaults.standard.string(forKey: "lastSelectedLedgerId"),
           let uuid = UUID(uuidString: lastSelectedId) {
            return ledgers.first { $0.id == uuid }
        }
        return ledgers.first
    }
    
    var ledgerTags: [Tag] {
        tags.filter { $0.ledger?.id == currentLedger?.id }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if ledgerTags.isEmpty {
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "tag")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            Text("暂无标签")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("创建标签来更好地管理你的账单")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Button {
                                editingTag = nil
                                showingTagEditor = true
                            } label: {
                                Text("创建标签")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(width: 150, height: 44)
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                } else {
                    Section("我的标签") {
                        ForEach(ledgerTags) { tag in
                            TagRowView(tag: tag) {
                                editingTag = tag
                                showingTagEditor = true
                            }
                        }
                        .onDelete(perform: deleteTags)
                    }
                }
            }
            .navigationTitle("标签管理")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        editingTag = nil
                        showingTagEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingTagEditor) {
                TagEditorView(tag: editingTag, ledger: currentLedger) { name, colorHex in
                    saveTag(name: name, colorHex: colorHex)
                }
            }
        }
    }
    
    private func deleteTags(at offsets: IndexSet) {
        for index in offsets {
            let tag = ledgerTags[index]
            modelContext.delete(tag)
        }
        try? modelContext.save()
    }
    
    private func saveTag(name: String, colorHex: String) {
        if let tag = editingTag {
            tag.name = name
            tag.colorHex = colorHex
        } else {
            let newTag = Tag(name: name, colorHex: colorHex, ledger: currentLedger)
            modelContext.insert(newTag)
        }
        try? modelContext.save()
    }
}

struct TagRowView: View {
    let tag: Tag
    let onEdit: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: tag.colorHex))
                .frame(width: 24, height: 24)
            
            Text(tag.name)
                .font(.body)
            
            Spacer()
            
            Text("\(tag.bills?.count ?? 0)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
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

struct TagEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let tag: Tag?
    let ledger: Ledger?
    let onSave: (String, String) -> Void
    
    @State private var name: String
    @State private var selectedColor: String
    
    private let colors = [
        "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4",
        "#FFEAA7", "#DDA0DD", "#98D8C8", "#2ECC71",
        "#3498DB", "#9B59B6", "#F6C744", "#E74C3C"
    ]
    
    init(tag: Tag?, ledger: Ledger?, onSave: @escaping (String, String) -> Void) {
        self.tag = tag
        self.ledger = ledger
        self.onSave = onSave
        _name = State(initialValue: tag?.name ?? "")
        _selectedColor = State(initialValue: tag?.colorHex ?? "#5B7CFA")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("标签名称") {
                    TextField("请输入标签名称", text: $name)
                }
                
                Section("选择颜色") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                        ForEach(colors, id: \.self) { color in
                            Button {
                                selectedColor = color
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: color))
                                        .frame(width: 44, height: 44)
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
                        Circle()
                            .fill(Color(hex: selectedColor))
                            .frame(width: 24, height: 24)
                        Text(name.isEmpty ? "标签名称" : name)
                            .foregroundColor(name.isEmpty ? .secondary : .primary)
                    }
                }
            }
            .navigationTitle(tag == nil ? "新建标签" : "编辑标签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(name, selectedColor)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    TagManagementView()
        .modelContainer(for: [Ledger.self, Bill.self, Tag.self], inMemory: true)
}