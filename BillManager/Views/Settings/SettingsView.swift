import SwiftUI
import SwiftData
#if !os(macOS)
import UIKit
#endif

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
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                
                ledgerSection
                
                generalSection
                
                dataSection
                
                aboutSection
            }
            .padding()
        }
        .background(Color(red: 250/255, green: 250/255, blue: 249/255))
        .sheet(isPresented: $showingLedgerManager) {
            LedgerListView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }
    
    private var headerSection: some View {
        HStack {
            Text("设置")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color(red: 28/255, green: 25/255, blue: 23/255))
            Spacer()
        }
        .padding(.top, 60)
    }

    private var ledgerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("账本")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(red: 168/255, green: 162/255, blue: 158/255))
            
            VStack(spacing: 0) {
                settingsRow(
                    icon: "book.fill",
                    iconBgColor: Color(red: 245/255, green: 158/255, blue: 11/255).opacity(0.15),
                    iconColor: Color(red: 245/255, green: 158/255, blue: 11/255),
                    title: "当前账本",
                    value: currentLedger?.name ?? "默认账本"
                )
                
                Divider()
                    .padding(.leading, 60)
                
                Button {
                    showingLedgerManager = true
                } label: {
                    settingsRow(
                        icon: "folder.fill",
                        iconBgColor: Color.blue.opacity(0.15),
                        iconColor: .blue,
                        title: "管理账本",
                        showChevron: true
                    )
                }
            }
            .background(Color.white)
            .cornerRadius(40)
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        }
    }
    
    private func settingsRow(icon: String, iconBgColor: Color, iconColor: Color, title: String, value: String? = nil, showChevron: Bool = false) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconBgColor)
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
            }
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(red: 28/255, green: 25/255, blue: 23/255))
            
            Spacer()
            
            if let value = value {
                Text(value)
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 168/255, green: 162/255, blue: 158/255))
            }
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 120/255, green: 113/255, blue: 108/255))
            }
        }
        .padding(16)
    }

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("通用")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(red: 168/255, green: 162/255, blue: 158/255))
            
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 16/255, green: 185/255, blue: 129/255).opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color(red: 16/255, green: 185/255, blue: 129/255))
                    }
                    
                    Text("货币")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(red: 28/255, green: 25/255, blue: 23/255))
                    
                    Spacer()
                    
                    Picker("", selection: $defaultCurrency) {
                        Text("人民币 (CNY)").tag("CNY")
                        Text("美元 (USD)").tag("USD")
                        Text("欧元 (EUR)").tag("EUR")
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                .padding(16)
                
                Divider()
                    .padding(.leading, 60)
                
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.indigo.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "calendar")
                            .font(.system(size: 18))
                            .foregroundColor(.indigo)
                    }
                    
                    Text("日期格式")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(red: 28/255, green: 25/255, blue: 23/255))
                    
                    Spacer()
                    
                    Picker("", selection: $dateFormat) {
                        Text("yyyy-MM-dd").tag("yyyy-MM-dd")
                        Text("yyyy/MM/dd").tag("yyyy/MM/dd")
                        Text("MM/dd").tag("MM/dd")
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                .padding(16)
            }
            .background(Color.white)
            .cornerRadius(40)
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        }
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("数据")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(red: 168/255, green: 162/255, blue: 158/255))
            
            VStack(spacing: 0) {
                Button {
                    exportData()
                } label: {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color(red: 245/255, green: 158/255, blue: 11/255).opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18))
                                .foregroundColor(Color(red: 245/255, green: 158/255, blue: 11/255))
                        }
                        
                        Text("导出数据")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(red: 245/255, green: 158/255, blue: 11/255))
                        
                        Spacer()
                    }
                    .padding(16)
                }
                
                Divider()
                    .padding(.leading, 60)
                
                Button(role: .destructive) {
                    clearAllData()
                } label: {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color(red: 244/255, green: 63/255, blue: 94/255).opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: "trash")
                                .font(.system(size: 18))
                                .foregroundColor(Color(red: 244/255, green: 63/255, blue: 94/255))
                        }
                        
                        Text("清空所有数据")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(red: 244/255, green: 63/255, blue: 94/255))
                        
                        Spacer()
                    }
                    .padding(16)
                }
            }
            .background(Color.white)
            .cornerRadius(40)
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("关于")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(red: 168/255, green: 162/255, blue: 158/255))
            
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "info.circle")
                            .font(.system(size: 18))
                            .foregroundColor(Color(red: 168/255, green: 162/255, blue: 158/255))
                    }
                    
                    Text("版本")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(red: 28/255, green: 25/255, blue: 23/255))
                    
                    Spacer()
                    
                    Text("1.0.0")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 168/255, green: 162/255, blue: 158/255))
                }
                .padding(16)
                
                Divider()
                    .padding(.leading, 60)
                
                Button {
                    showingAbout = true
                } label: {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 18))
                                .foregroundColor(Color(red: 168/255, green: 162/255, blue: 158/255))
                        }
                        
                        Text("关于我们")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(red: 28/255, green: 25/255, blue: 23/255))
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 120/255, green: 113/255, blue: 108/255))
                    }
                    .padding(16)
                }
            }
            .background(Color.white)
            .cornerRadius(40)
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
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
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color(red: 245/255, green: 158/255, blue: 11/255))

                    Text("记账管理器")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(red: 28/255, green: 25/255, blue: 23/255))

                    Text("版本 1.0.0")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 168/255, green: 162/255, blue: 158/255))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("简介")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 168/255, green: 162/255, blue: 158/255))
                    
                    Text("一款简洁高效的跨平台记账应用，帮助您轻松管理个人财务。")
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 28/255, green: 25/255, blue: 23/255))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(Color.white)
                .cornerRadius(24)
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("技术栈")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 168/255, green: 162/255, blue: 158/255))
                    
                    Text("使用 SwiftUI + SwiftData + Swift Charts 构建")
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 28/255, green: 25/255, blue: 23/255))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(Color.white)
                .cornerRadius(24)
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
            }
            .padding()
        }
        .background(Color(red: 250/255, green: 250/255, blue: 249/255))
        .navigationTitle("关于")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("完成") { dismiss() }
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Ledger.self, Bill.self, Category.self], inMemory: true)
}