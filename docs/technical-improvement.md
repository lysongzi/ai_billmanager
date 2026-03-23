# 记账应用技术改进方案

## 一、当前问题分析

### 1.1 架构问题

当前代码将业务逻辑直接分散在 View 层中，导致：
- **职责不清**：View 既负责 UI 渲染，又处理业务逻辑
- **难以测试**：业务逻辑与 UI 耦合，无法单独单元测试
- **维护困难**：相同逻辑在多处重复，修改时容易遗漏
- **可扩展性差**：新增功能需要修改现有 View

### 1.2 目录结构问题

| 目录 | 现状 | 问题 |
|------|------|------|
| ViewModels/ | 空目录 | 业务逻辑未封装 |
| Services/ | 空目录 | 数据操作未统一 |
| Components/ | 空目录 | 可复用组件未提取 |

## 二、改进目标

1. **清晰的职责分离**：View → ViewModel → Service → Model
2. **可测试性**：业务逻辑可单独单元测试
3. **代码复用**：提取通用组件，减少重复代码
4. **可维护性**：修改逻辑时影响范围可控

## 三、改进方案

### 3.1 目录结构改进

```
BillManager/
├── App/
│   ├── BillManagerApp.swift
│   └── ContentView.swift
├── Models/
│   ├── Ledger.swift
│   ├── Bill.swift
│   ├── Category.swift
│   └── Statistics.swift
├── ViewModels/                    # 新增
│   ├── LedgerViewModel.swift
│   ├── BillViewModel.swift
│   └── StatisticsViewModel.swift
├── Views/
│   ├── Ledgers/
│   ├── Bills/
│   ├── Statistics/
│   └── Settings/
├── Services/                      # 新增
│   ├── DataService.swift
│   └── ExportService.swift
├── Components/                    # 新增
│   ├── AmountInputView.swift
│   ├── CategoryPicker.swift
│   ├── DatePickerView.swift
│   └── SummaryCard.swift
├── Utilities/
│   ├── Extensions.swift
│   └── Constants.swift
└── Resources/
```

### 3.2 ViewModel 层设计

#### LedgerViewModel

```swift
@Observable
final class LedgerViewModel {
    private let modelContext: ModelContext
    
    var ledgers: [Ledger] = []
    var currentLedger: Ledger?
    var isLoading = false
    var errorMessage: String?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadLedgers()
    }
    
    func loadLedgers()
    func createLedger(name: String, icon: String, colorHex: String)
    func updateLedger(_ ledger: Ledger, name: String, icon: String, colorHex: String)
    func deleteLedger(_ ledger: Ledger)
    func archiveLedger(_ ledger: Ledger)
    func restoreLedger(_ ledger: Ledger)
    func selectLedger(_ ledger: Ledger)
    func getCurrentLedger() -> Ledger?
}
```

#### BillViewModel

```swift
@Observable
final class BillViewModel {
    private let modelContext: ModelContext
    
    var bills: [Bill] = []
    var filteredBills: [Bill] = []
    var searchText = ""
    var selectedDate: Date = Date()
    var isLoading = false
    
    init(modelContext: ModelContext, ledger: Ledger) {
        self.modelContext = modelContext
        self.ledger = ledger
        loadBills()
    }
    
    func loadBills()
    func createBill(_ bill: Bill)
    func updateBill(_ bill: Bill)
    func deleteBill(_ bill: Bill)
    func search(text: String)
    func filterByDate(_ date: Date)
    func getTotalIncome() -> Double
    func getTotalExpense() -> Double
    func getBalance() -> Double
}
```

#### StatisticsViewModel

```swift
@Observable
final class StatisticsViewModel {
    private let modelContext: ModelContext
    
    var currentLedger: Ledger?
    var selectedTimeRange: TimeRange = .month
    var selectedBillType: BillType = .expense
    var statistics: Statistics?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func loadStatistics()
    func selectLedger(_ ledger: Ledger)
    func selectTimeRange(_ range: TimeRange)
    func selectBillType(_ type: BillType)
    func getCategoryStats() -> [CategoryStat]
    func getDailyStats() -> [DailyStat]
}
```

### 3.3 Service 层设计

#### DataService

```swift
final class DataService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // 账本操作
    func fetchAllLedgers() -> [Ledger]
    func fetchLedger(by id: UUID) -> Ledger?
    func saveLedger(_ ledger: Ledger)
    func deleteLedger(_ ledger: Ledger)
    
    // 账单操作
    func fetchBills(for ledger: Ledger) -> [Bill]
    func saveBill(_ bill: Bill, to ledger: Ledger)
    func deleteBill(_ bill: Bill)
    
    // 分类操作
    func fetchCategories(for ledger: Ledger) -> [Category]
    func createDefaultCategories() -> [Category]
    
    // 初始化
    func initializeDefaultLedgerIfNeeded()
}
```

#### ExportService

```swift
final class ExportService {
    func exportToCSV(bills: [Bill], format: String) -> URL?
    func exportToJSON(bills: [Bill]) -> URL?
}
```

### 3.4 Components 层设计

#### AmountInputView
金额输入组件，支持键盘类型配置

#### CategoryPicker
分类选择器，支持网格布局

#### DatePickerView
日期选择器，支持快捷选择今天/昨天

#### SummaryCard
收支摘要卡片组件

### 3.5 架构流程图

```
┌─────────────────────────────────────────────────────────────────┐
│                         Views                                    │
│  LedgerListView / BillListView / StatisticsView                 │
└─────────────────────────────┬───────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      ViewModels                                  │
│  LedgerViewModel / BillViewModel / StatisticsViewModel          │
│  - 状态管理                                                      │
│  - 业务逻辑处理                                                  │
│  - 数据转换                                                      │
└─────────────────────────────┬───────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       Services                                   │
│  DataService / ExportService                                    │
│  - 数据持久化                                                    │
│  - 跨模型操作                                                    │
│  - 导出逻辑                                                      │
└─────────────────────────────┬───────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      SwiftData                                   │
│  Ledger / Bill / Category                                       │
└─────────────────────────────────────────────────────────────────┘
```

## 四、实施计划

### Phase 1: ViewModels 提取

1. 创建 `LedgerViewModel`，迁移账本相关业务逻辑
2. 创建 `BillViewModel`，迁移账单相关业务逻辑
3. 创建 `StatisticsViewModel`，迁移统计相关业务逻辑
4. 更新 Views 引用 ViewModels

### Phase 2: Services 提取

1. 创建 `DataService`，封装数据操作
2. 创建 `ExportService`，封装导出逻辑
3. 移除 Views 中的直接 modelContext 操作

### Phase 3: Components 提取

1. 提取 `AmountInputView`
2. 提取 `CategoryPicker`
3. 提取 `SummaryCard`
4. 整理现有代码中的重复 UI 片段

## 五、测试策略

详见 `test-plan.md`

## 六、预期收益

| 指标 | 改进前 | 改进后 |
|------|--------|--------|
| 业务逻辑复用性 | 低 | 高 |
| 单元测试覆盖 | 0% | 70%+ |
| 代码行数（业务逻辑） | 分散 | 集中 |
| 新功能开发效率 | 中 | 高 |
| Bug影响范围 | 难定位 | 局部 |