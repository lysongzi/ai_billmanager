import SwiftUI
import SwiftData
import UIKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var ledgers: [Ledger]
    @AppStorage("defaultCurrency") private var defaultCurrency: String = "CNY"
    @AppStorage("dateFormat") private var dateFormat: String = "yyyy-MM-dd"

    @State private var showingLedgerManager = false
    @State private var showingExportSheet = false
    @State private var showingAbout = false

    var currentLedger: Ledger? {
        if let lastSelectedId = UserDefaults.standard.string(forKey: "lastSelectedLedgerId"),
           let uuid = UUID(uuidString: lastSelectedId) {
            return ledgers.first { $0.id == uuid }
        }
        return ledgers.first
    }

    var body: some View {
        NavigationStack {
            List {
                currentLedgerSection

                generalSection

                dataSection

                aboutSection
            }
            .navigationTitle("设置")
            .sheet(isPresented: $showingLedgerManager) {
                LedgerListView()
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
    }

    private var currentLedgerSection: some View {
        Section {
            HStack {
                Label("当前账本", systemImage: "book.fill")

                Spacer()

                if let ledger = currentLedger {
                    Text(ledger.name)
                        .foregroundColor(.secondary)
                }
            }

            Button {
                showingLedgerManager = true
            } label: {
                Label("管理账本", systemImage: "folder.fill")
            }
        } header: {
            Text("账本")
        }
    }

    private var generalSection: some View {
        Section {
            Picker(selection: $defaultCurrency) {
                Text("人民币 (CNY)").tag("CNY")
                Text("美元 (USD)").tag("USD")
                Text("欧元 (EUR)").tag("EUR")
                Text("日元 (JPY)").tag("JPY")
                Text("英镑 (GBP)").tag("GBP")
            } label: {
                Label("货币", systemImage: "dollarsign.circle")
            }

            Picker(selection: $dateFormat) {
                Text("yyyy-MM-dd").tag("yyyy-MM-dd")
                Text("yyyy/MM/dd").tag("yyyy/MM/dd")
                Text("MM/dd").tag("MM/dd")
                Text("dd/MM").tag("dd/MM")
            } label: {
                Label("日期格式", systemImage: "calendar")
            }
        } header: {
            Text("通用")
        }
    }

    private var dataSection: some View {
        Section {
            Button {
                exportData()
            } label: {
                Label("导出数据", systemImage: "square.and.arrow.up")
            }

            Button(role: .destructive) {
                clearAllData()
            } label: {
                Label("清空所有数据", systemImage: "trash")
            }
        } header: {
            Text("数据")
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Label("版本", systemImage: "info.circle")
                Spacer()
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }

            Button {
                showingAbout = true
            } label: {
                Label("关于", systemImage: "questionmark.circle")
            }
        } header: {
            Text("关于")
        }
    }

    private func exportData() {
        guard let ledger = currentLedger,
              let bills = ledger.bills else { return }

        var csvContent = "日期,类型,分类,金额,备注\n"

        for bill in bills.sorted(by: { $0.date > $1.date }) {
            let dateStr = bill.date.formatted(as: dateFormat)
            let typeStr = bill.type == .income ? "收入" : "支出"
            let note = bill.note?.replacingOccurrences(of: ",", with: ";") ?? ""
            let row = "\(dateStr),\(typeStr),\(bill.categoryName),\(bill.amount),\(note)\n"
            csvContent += row
        }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(ledger.name)_账单导出.csv")

        do {
            try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        } catch {
            print("导出失败: \(error)")
        }
    }

    private func clearAllData() {
        for ledger in ledgers {
            modelContext.delete(ledger)
        }
        try? modelContext.save()

        UserDefaults.standard.removeObject(forKey: "lastSelectedLedgerId")
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor)

                        Text("记账管理器")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("版本 1.0.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }

                Section {
                    Text("一款简洁高效的跨平台记账应用，帮助您轻松管理个人财务。")
                        .font(.body)
                } header: {
                    Text("简介")
                }

                Section {
                    Text("使用 SwiftUI + SwiftData + Swift Charts 构建")
                        .font(.body)
                } header: {
                    Text("技术栈")
                }
            }
            .navigationTitle("关于")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Ledger.self, Bill.self, Category.self], inMemory: true)
}