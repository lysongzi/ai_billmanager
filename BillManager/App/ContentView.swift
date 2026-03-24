import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var ledgers: [Ledger]
    
    @State private var selectedTab = 0
    @State private var showingQuickAdd = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: 明细（首页Dashboard）
            DashboardView()
                .tabItem {
                    Label("明细", systemImage: "list.bullet")
                }
                .tag(0)
            
            // Tab 2: 图表
            StatisticsView()
                .tabItem {
                    Label("图表", systemImage: "chart.pie.fill")
                }
                .tag(1)
            
            // Tab 3: 空白（用于FAB占位）
            Color.clear
                .tabItem {
                    Label("记账", systemImage: "plus.circle.fill")
                }
                .tag(2)
            
            // Tab 4: 发现（预算+资产）
            BudgetView()
                .tabItem {
                    Label("发现", systemImage: "lightbulb.fill")
                }
                .tag(3)
            
            // Tab 5: 我的
            ProfileView()
                .tabItem {
                    Label("我的", systemImage: "person.fill")
                }
                .tag(4)
        }
        .tint(Color(hex: "#F6C744"))
        .onAppear {
            setupTabBarAppearance()
            initializeDefaultLedgerIfNeeded()
        }
        .overlay(alignment: .bottom) {
            // 自定义FAB按钮
            FABButton {
                showingQuickAdd = true
            }
            .offset(y: -20)
            .opacity(selectedTab == 0 || selectedTab == 2 ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: selectedTab)
        }
        .sheet(isPresented: $showingQuickAdd) {
            QuickAddView(ledger: getCurrentLedger()) { bill in
                saveBill(bill)
            }
        }
    }
    
    private func getCurrentLedger() -> Ledger {
        if let lastSelectedId = UserDefaults.standard.string(forKey: "lastSelectedLedgerId"),
           let uuid = UUID(uuidString: lastSelectedId),
           let ledger = ledgers.first(where: { $0.id == uuid }) {
            return ledger
        }
        return ledgers.first ?? Ledger(name: "默认账本")
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
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
    
    private func saveBill(_ bill: Bill) {
        let ledger = getCurrentLedger()
        if ledger.bills == nil {
            ledger.bills = []
        }
        ledger.bills?.append(bill)
        try? modelContext.save()
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
            categories.append(Category(name: name, icon: icon, colorHex: color, type: .expense))
        }
        
        for (name, icon, color) in incomeCategories {
            categories.append(Category(name: name, icon: icon, colorHex: color, type: .income))
        }
        
        return categories
    }
}

// MARK: - FAB Button

struct FABButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#F6C744"))
                    .frame(width: 56, height: 56)
                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Ledger.self, Bill.self, Category.self, Tag.self, Budget.self], inMemory: true)
}