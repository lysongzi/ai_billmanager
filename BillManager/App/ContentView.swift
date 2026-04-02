import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var ledgers: [Ledger]

    var body: some View {
        TabView {
            NavigationStack {
                LedgerListView()
            }
            .tabItem {
                Label("账本", systemImage: "book.fill")
            }

            StatisticsView()
                .tabItem {
                    Label("统计", systemImage: "chart.pie.fill")
                }

            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape.fill")
                }
        }
        .onAppear {
            initializeDefaultLedgerIfNeeded()
        }
    }

    private func initializeDefaultLedgerIfNeeded() {
        if ledgers.isEmpty {
            let defaultLedger = Ledger(
                name: "默认账本",
                icon: "book.fill",
                colorHex: "#007AFF"
            )
            defaultLedger.categories = createDefaultCategories()
            modelContext.insert(defaultLedger)

            UserDefaults.standard.set(defaultLedger.id.uuidString, forKey: "lastSelectedLedgerId")

            try? modelContext.save()
        }
    }

    private func createDefaultCategories() -> [Category] {
        let expenseCategories = [
            ("餐饮", "fork.knife", "#FF6B6B"),
            ("交通", "car.fill", "#4ECDC4"),
            ("购物", "bag.fill", "#45B7D1"),
            ("娱乐", "gamecontroller.fill", "#96CEB4"),
            ("居住", "house.fill", "#FFEAA7"),
            ("医疗", "cross.fill", "#DDA0DD"),
            ("通讯", "phone.fill", "#98D8C8"),
            ("其他", "ellipsis.circle.fill", "#B8B8B8")
        ]

        let incomeCategories = [
            ("工资", "banknote.fill", "#2ECC71"),
            ("奖金", "gift.fill", "#27AE60"),
            ("投资收益", "chart.line.uptrend.xyaxis", "#3498DB"),
            ("其他收入", "plus.circle.fill", "#9B59B6")
        ]

        var categories: [Category] = []

        for (name, icon, color) in expenseCategories {
            let category = Category(name: name, icon: icon, colorHex: color, type: .expense)
            categories.append(category)
        }

        for (name, icon, color) in incomeCategories {
            let category = Category(name: name, icon: icon, colorHex: color, type: .income)
            categories.append(category)
        }

        return categories
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Ledger.self, Bill.self, Category.self], inMemory: true)
}