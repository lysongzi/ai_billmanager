# 记账应用技术方案设计

## 一、技术选型

### 1.1 跨平台框架

**推荐方案：SwiftUI + SwiftUI Lifecycle**

| 方案 | 优势 | 劣势 |
|------|------|------|
| **SwiftUI (推荐)** | 原生体验，代码复用率高 | iOS 17+ |
| UIKit | 成熟稳定 | 维护两套代码 |
| Flutter | 跨平台能力强 | 非原生体验 |

**推荐理由**：
- SwiftUI 可以使用同一套代码同时运行在 iOS 和 Mac 上
- Apple Silicon Mac 可直接运行 iOS/iPadOS 应用
- 最新的 SwiftUI 提供了完善的 Charts 框架用于数据可视化

### 1.2 技术栈

| 层级 | 技术选型 | 说明 |
|------|----------|------|
| UI框架 | SwiftUI | 跨平台声明式UI |
| 数据存储 | SwiftData | Apple新一代ORM |
| 图表 | Swift Charts | Apple原生图表框架 |
| 状态管理 | @Observable | iOS 17新特性 |
| 本地化 | SwiftUI Localization | 多语言支持 |

## 二、架构设计

### 2.1 整体架构

```
┌─────────────────────────────────────────────┐
│                  Views                       │
│  (账本列表、记账、统计、设置)                  │
├─────────────────────────────────────────────┤
│               ViewModels                     │
│  (业务逻辑、数据处理)                         │
├─────────────────────────────────────────────┤
│                  Models                      │
│  (账本、账单、分类、统计)                      │
├─────────────────────────────────────────────┤
│                Services                      │
│  (DataService, ChartService)                 │
├─────────────────────────────────────────────┤
│                SwiftData                     │
│  (本地持久化存储)                             │
└─────────────────────────────────────────────┘
```

### 2.2 目录结构

```
BillManager/
├── App/
│   └── BillManagerApp.swift
├── Models/
│   ├── Ledger.swift          # 账本模型
│   ├── Bill.swift            # 账单模型
│   ├── Category.swift        # 分类模型
│   └── Statistics.swift      # 统计数据模型
├── Views/
│   ├── Ledgers/
│   │   ├── LedgerListView.swift
│   │   └── LedgerDetailView.swift
│   ├── Bills/
│   │   ├── BillListView.swift
│   │   ├── BillEditView.swift
│   │   └── BillQuickAddView.swift
│   ├── Statistics/
│   │   ├── StatisticsView.swift
│   │   ├── ChartViews.swift
│   │   └── CategoryBreakdownView.swift
│   └── Settings/
│       └── SettingsView.swift
├── ViewModels/
│   ├── LedgerViewModel.swift
│   ├── BillViewModel.swift
│   └── StatisticsViewModel.swift
├── Services/
│   ├── DataService.swift
├── Components/
│   ├── AmountInputView.swift
│   ├── CategoryPicker.swift
│   └── DatePickerView.swift
├── Utilities/
│   ├── Extensions.swift
│   └── Constants.swift
└── Resources/
    ├── Assets.xcassets
    └── Localizable.strings
```

## 三、数据模型设计

### 3.1 核心模型

```swift
// 账本模型
@Model
class Ledger {
    var id: UUID
    var name: String           // 账本名称
    var icon: String           // 图标名称
    var colorHex: String       // 封面颜色
    var createdAt: Date
    var isArchived: Bool
    
    @Relationship(deleteRule: .cascade)
    var bills: [Bill]
    
    @Relationship(deleteRule: .cascade)
    var categories: [Category]
}

// 账单模型
@Model
class Bill {
    var id: UUID
    var amount: Double         // 金额
    var type: BillType         // 收入/支出
    var categoryName: String   // 分类名称
    var note: String?          // 备注
    var date: Date             // 记账日期
    var createdAt: Date
    var updatedAt: Date
    
    var ledger: Ledger?
}

// 分类模型
@Model
class Category {
    var id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var type: BillType         // 收入/支出
    
    var ledger: Ledger?
}

// 枚举类型
enum BillType: String, Codable {
    case income
    case expense
}
```

### 3.2 统计数据模型

```swift
struct Statistics {
    var totalIncome: Double
    var totalExpense: Double
    var balance: Double
    var categoryBreakdown: [CategoryStat]
    var dailyTrend: [DailyStat]
}

struct CategoryStat: Identifiable {
    var id: UUID
    var categoryName: String
    var icon: String
    var colorHex: String
    var amount: Double
    var percentage: Double
}

struct DailyStat: Identifiable {
    var id: Date
    var date: Date
    var income: Double
    var expense: Double
}
```

## 四、核心功能设计

### 4.1 账本管理

**功能列表**：
- 创建账本（名称、图标、颜色）
- 编辑账本
- 删除账本（确认弹窗）
- 归档账本
- 账本列表展示（总资产显示）
- **首次启动自动创建"默认账本"**
- **记住上次使用的账本**

**首次启动初始化**：
```swift
// App 启动时检查并初始化
func initializeDefaultLedgerIfNeeded() {
    let ledgers = fetchAllLedgers()
    if ledgers.isEmpty {
        // 首次启动，创建默认账本
        let defaultLedger = Ledger(
            name: "默认账本",
            icon: "book.fill",
            colorHex: "#007AFF"
        )
        let defaultCategories = createDefaultCategories()
        defaultLedger.categories = defaultCategories
        modelContext.insert(defaultLedger)
        
        // 保存当前账本ID
        UserDefaults.standard.set(defaultLedger.id.uuidString, 
                                  forKey: "lastSelectedLedgerId")
    }
}
```

**记住上次使用的账本**：
```swift
// 保存当前账本
func saveLastSelectedLedger(_ ledger: Ledger) {
    UserDefaults.standard.set(ledger.id.uuidString, 
                              forKey: "lastSelectedLedgerId")
}

// 获取上次使用的账本
func getLastSelectedLedger() -> Ledger? {
    guard let uuidString = UserDefaults.standard.string(forKey: "lastSelectedLedgerId"),
          let uuid = UUID(uuidString: uuidString) else {
        return nil
    }
    return fetchLedger(by: uuid)
}

// 启动时自动进入上次使用的账本
func getInitialLedger() -> Ledger {
    return getLastSelectedLedger() ?? fetchAllLedgers().first!
}
```

**账本创建**：
```swift
func createLedger(name: String, icon: String, colorHex: String) {
    let ledger = Ledger(name: name, icon: icon, colorHex: colorHex)
    let defaultCategories = createDefaultCategories()
    ledger.categories = defaultCategories
    modelContext.insert(ledger)
}
```

### 4.2 账单管理

**CRUD 操作**：

| 操作 | 路径 | 说明 |
|------|------|------|
| 创建 | BillEditView | 完整账单编辑 |
| 读取 | BillListView | 列表展示，支持筛选 |
| 更新 | BillEditView | 修改账单信息 |
| 删除 | 滑动删除 | 确认后执行 |

**快捷记账**：
- 支持金额输入+分类选择快速创建
- 支持 Siri Shortcuts 语音创建

### 4.3 页面设计与导航

#### 4.3.1 页面清单（共 9 个核心页面）

| 序号 | 页面 | 说明 |
|------|------|------|
| 1 | **LedgerListView** | 账本列表首页，选择/管理账本 |
| 2 | **LedgerDetailView** | 账本详情，展示账单列表入口 |
| 3 | **BillListView** | 账单列表，展示某账本下所有账单 |
| 4 | **BillEditView** | 账单编辑（创建/编辑） |
| 5 | **BillQuickAddView** | 快捷记账浮窗/页面 |
| 6 | **StatisticsView** | 统计分析首页 |
| 7 | **ChartViews** | 图表展示（饼图/折线图/柱状图） |
| 8 | **CategoryBreakdownView** | 分类明细 breakdown |
| 9 | **SettingsView** | 设置页 |

#### 4.3.2 页面关系图

```
┌─────────────────────────────────────────────────────────────────┐
│                        App Entry                                 │
│                    (BillManagerApp)                              │
└─────────────────────────────┬───────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                 LedgerListView (账本列表)                        │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  [账本1]  [账本2]  [账本3]  +新增账本                       │  │
│  └───────────────────────────────────────────────────────────┘  │
└──────────┬──────────────────────────────────────────────────────┘
           │
     ┌─────┴─────┬─────────────────┐
     ▼           ▼                 ▼
┌──────────┐ ┌──────────┐   ┌──────────────┐
│ 统计入口  │ │ 账单列表  │   │  设置入口    │
│  (Tab)   │ │  (Tab)   │   │   (Tab)      │
└────┬─────┘ └────┬─────┘   └──────┬───────┘
     │            │                 │
     ▼            ▼                 ▼
┌──────────────┐ ┌────────────┐   ┌──────────────┐
│StatisticsView│ │BillListView│   │SettingsView  │
│   (统计页)   │ │ (账单列表)  │   │   (设置页)   │
└──────┬───────┘ └─────┬──────┘   └──────────────┘
       │               │
       │         ┌─────┴──────┬──────────────┐
       │         ▼            ▼              ▼
       │   ┌──────────┐ ┌──────────┐ ┌──────────────┐
       │   │ 快速记账  │ │ 编辑账单  │ │  删除账单    │
       │   │(QuickAdd)│ │(EditView)│ │  (Swipe)     │
       │   └──────────┘ └──────────┘ └──────────────┘
       │
       ▼
┌──────────────┬──────────────┬─────────────────┐
│  ChartViews  │CategoryBreak │                  │
│  (图表展示)  │(分类明细)    │                  │
└──────────────┴──────────────┴─────────────────┘
```

#### 4.3.3 导航结构

```
TabView (3个Tab)
├── Tab 1: 账本/账单
│   ├── LedgerListView
│   │   └── LedgerDetailView
│   │       └── BillListView
│   │           ├── BillEditView (编辑)
│   │           └── BillQuickAddView (新增)
├── Tab 2: 统计
│   ├── StatisticsView
│   │   ├── ChartViews (饼图/折线图)
│   │   └── CategoryBreakdownView
└── Tab 3: 设置
    └── SettingsView
```

### 4.4 统计分析

**时间维度**：
- 本周（周一至周日）
- 本月
- 本年
- 自定义范围

**图表展示**：

| 图表类型 | 用途 | 使用场景 |
|----------|------|----------|
| 饼图 | 分类占比 | 支出/收入分类统计 |
| 折线图 | 趋势变化 | 日/周/月收支趋势 |
| 柱状图 | 对比分析 | 月度对比 |

**Swift Charts 实现**：

```swift
// 饼图 - 分类占比
Chart(categoryStats) { stat in
    SectorMark(
        angle: .value("Amount", stat.amount),
        innerRadius: .ratio(0.5),
        angularInset: 1
    )
    .foregroundStyle(stat.colorHex)
    .cornerRadius(4)
}

// 折线图 - 趋势
Chart(dailyTrend) { stat in
    LineMark(
        x: .value("Date", stat.date),
        y: .value("Amount", stat.expense)
    )
    .foregroundStyle(.red)
    
    LineMark(
        x: .value("Date", stat.date),
        y: .value("Amount", stat.income)
    )
    .foregroundStyle(.green)
}
```

## 五、跨平台适配

### 5.1 iOS vs Mac 布局差异

| 特性 | iOS | Mac |
|------|-----|-----|
| 导航 | TabView | Sidebar + TabView |
| 布局 | 紧凑型 | 可使用更大空间 |
| 窗口 | 全屏 | 支持多窗口 |
| 快捷键 | 不适用 | 支持键盘快捷键 |

### 5.2 响应式设计

```swift
// 自适应布局
struct ContentView: View {
    var body: some View {
        NavigationSplitView {
            SidebarView()
        } content: {
            ListView()
        } detail: {
            DetailView()
        }
    }
}
```

## 六、数据存储

### 6.1 本地存储方案

采用 SwiftData 进行本地数据持久化，数据存储在设备本地。

```swift
// SwiftData 本地存储配置
@main
struct BillManagerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Ledger.self, Bill.self, Category.self])
    }
}
```

### 6.2 数据策略

| 场景 | 策略 |
|------|------|
| 新建账单 | 立即持久化 |
| 修改账单 | 实时保存 |
| 删除账单 | 物理删除 |
| 应用启动 | 加载全部数据到内存 |

> **后续版本**：可扩展支持 CloudKit 同步（v1.2.0）

## 七、测试计划

### 7.1 单元测试

- 数据模型 CRUD 测试
- 统计计算逻辑测试
- 日期筛选逻辑测试

### 7.2 UI 测试

- 账本创建/编辑流程
- 账单 CRUD 流程
- 图表渲染测试

### 7.3 兼容性测试

- iOS 17 / iOS 18
- macOS 14 / macOS 15
- 不同屏幕尺寸 (iPhone SE → iPad Pro)

## 八、发布计划

| 阶段 | 版本 | 目标 |
|------|------|------|
| MVP | 1.0.0 | 核心功能上线（账本管理、账单CRUD、统计分析） |
| v1.1 | 1.1.0 | 图表优化，数据导出 |
| v2.0 | 2.0.0 | 预算管理，周期记账 |
| v2.1 | 2.1.0 | 5-Tab导航、FAB记账、标签管理（当前版本） |

## 九、已实现功能

### 9.1 导航结构（5-Tab）

| Tab | 名称 | 功能 |
|-----|------|------|
| Tab 1 | 明细 | Dashboard首页（财务总览+账单列表） |
| Tab 2 | 图表 | 统计分析（饼图、折线图、分类明细） |
| Tab 3 | 记账 | FAB快捷记账按钮 |
| Tab 4 | 发现 | 预算管理、资产概览、智能洞察 |
| Tab 5 | 我的 | 账本管理、分类管理、标签管理、设置 |

### 9.2 数据模型

```swift
// 核心模型
@Model Ledger        // 账本
@Model Bill          // 账单
@Model Category      // 分类
@Model Budget        // 预算（新增）
@Model Tag           // 标签（新增）
```

### 9.3 核心页面

- **DashboardView**: 首页，包含账本切换、月份选择、收支概览、快捷操作、账单列表
- **StatisticsView**: 统计页，类型/时间筛选、饼图、趋势图、分类明细
- **BudgetView**: 发现页，预算设置与进度、资产概览、洞察提醒
- **ProfileView**: 我的页面，整合账本/分类/标签管理入口
- **TagManagementView**: 标签管理，CRUD操作
- **CategoryManagementView**: 分类管理，支出/收入分类CRUD

## 十、总结

本技术方案基于 SwiftUI + SwiftData 构建，充分利用 Apple 生态系统的原生能力，实现跨 iOS/Mac 平台的记账应用。方案重点关注：

1. **代码复用**：一套代码同时支持双平台
2. **数据安全**：SwiftData 提供本地安全存储
3. **用户体验**：原生 SwiftUI 组件确保流畅体验
4. **可扩展性**：模块化架构便于后续功能迭代