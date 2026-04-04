# BillManager 系统架构设计文档

**版本**: v1.0
**日期**: 2026-04-03
**作者**: 系统架构师（同事二）
**适用项目**: BillManager iOS 记账应用
**技术栈**: Swift 5.9 + SwiftUI + SwiftData + iOS 17+

---

## 目录

1. [架构总览](#1-架构总览)
2. [目录结构设计](#2-目录结构设计)
3. [各层详细接口设计](#3-各层详细接口设计)
4. [关键流程设计](#4-关键流程设计)
5. [Components 层设计](#5-components-层设计)
6. [重构开发任务拆分](#6-重构开发任务拆分)
7. [重构风险与注意事项](#7-重构风险与注意事项)

---

## 1. 架构总览

### 1.1 现有架构问题诊断

在启动重构之前，需明确当前架构存在以下具体痛点（均已在源码中验证）：

| 问题 | 具体表现 | 影响范围 |
|------|---------|---------|
| **视图直接操作 modelContext** | `BillListView.saveBill()` 中调用 `modelContext.delete(bill)` / `modelContext.save()` | BillListView, LedgerListView, SettingsView, ContentView |
| **业务逻辑混入视图** | `StatisticsView` 内直接计算 `categoryStats`、`dailyStats`，共计约 60 行计算逻辑 | StatisticsView |
| **数据初始化逻辑散落** | `ContentView.initializeDefaultLedgerIfNeeded()` 与 `LedgerListView.createDefaultCategories()` 存在重复逻辑 | ContentView, LedgerListView |
| **缺乏 ViewModel 层** | 所有 `@State` 变量、筛选逻辑、CRUD 操作全部堆积在 View 中 | 全部 View |
| **魔法字符串** | `UserDefaults.standard.set(..., forKey: "lastSelectedLedgerId")` 在三处 View 中重复出现 | StatisticsView, SettingsView, ContentView |
| **硬编码颜色值** | `StatisticsView` 中大量 `Color(red: 245/255, green: 158/255, blue: 11/255)` 直接使用，未走 DesignSystem | StatisticsView |
| **组件复用性不足** | `BillRowView`、`CategoryButton`、`LedgerCardView` 均内嵌于对应 View 文件，无法跨页面复用 | 全部 View |
| **DesignSystem 不完整** | 现有 `AppColors` 缺少 `appPrimarySurface`、`appDivider`、`appIncomeLight` 等 UI 规范要求的色彩 Token | DesignSystem.swift |
| **错误处理缺失** | `try? modelContext.save()` 全部忽略错误，无任何错误传播或用户提示 | 全部 View |

### 1.2 目标分层架构

```
┌─────────────────────────────────────────────────────────┐
│                      Views Layer                        │
│  纯 UI 展示，零业务逻辑，零 modelContext 操作            │
│  BillListView / LedgerListView / StatisticsView 等      │
├─────────────────────────────────────────────────────────┤
│                   Components Layer                      │
│  可复用 UI 原子组件（对应 UI 设计规范 13 个组件）        │
│  PrimaryButton / CardView / AmountDisplay 等            │
├─────────────────────────────────────────────────────────┤
│                   ViewModels Layer                      │
│  @Observable 视图模型，管理页面状态和 UI 逻辑            │
│  BillListViewModel / StatisticsViewModel 等             │
├─────────────────────────────────────────────────────────┤
│                    Services Layer                       │
│  业务逻辑服务，编排跨 Repository 的复杂操作              │
│  BillService / LedgerService / StatisticsService        │
├─────────────────────────────────────────────────────────┤
│                  Repositories Layer                     │
│  数据访问层，封装所有 SwiftData CRUD 操作               │
│  BillRepository / LedgerRepository / CategoryRepository │
├─────────────────────────────────────────────────────────┤
│                    Models Layer                         │
│  SwiftData @Model 数据模型（基本保持不变）               │
│  Bill / Ledger / Category / Statistics                  │
├─────────────────────────────────────────────────────────┤
│                Utilities & Extensions                   │
│  DesignSystem / Extensions / Constants                  │
└─────────────────────────────────────────────────────────┘
```

### 1.3 各层职责说明

| 层级 | 职责 | 禁止行为 |
|------|------|---------|
| **Views** | 声明 UI 结构；将用户事件转发给 ViewModel；绑定 ViewModel 的状态属性 | 不得直接访问 modelContext；不得执行任何计算逻辑 |
| **Components** | 提供无业务含义的通用 UI 原子组件；接受参数并渲染 | 不得持有任何状态（除内部交互动画 @State）；不得依赖 ViewModel |
| **ViewModels** | 管理页面状态（筛选条件、加载状态、错误信息等）；调用 Service 完成数据操作；格式化数据供 View 展示 | 不得直接操作 modelContext；不得包含 SwiftUI View 代码 |
| **Services** | 封装业务规则（如账单创建规则、统计算法）；协调多个 Repository 的操作；处理跨实体逻辑 | 不得包含 UI 逻辑；不得直接暴露 modelContext |
| **Repositories** | 封装 SwiftData 查询 / 插入 / 更新 / 删除操作；持有对 modelContext 的引用 | 不得包含业务规则；不得格式化数据 |
| **Models** | 定义 SwiftData `@Model` 实体；包含最基础的计算属性（如 `balance`） | 不得包含业务逻辑；不得依赖上层 |
| **Utilities** | 提供 Color/Font/Spacing Token；提供 Extensions；定义全局常量 | 不得依赖业务层 |

### 1.4 数据流向图

```
用户操作
    │
    ▼
View（绑定 ViewModel 的 @Published 属性）
    │ 调用方法
    ▼
ViewModel（持有 Service 引用）
    │ 调用业务方法
    ▼
Service（持有 Repository 引用）
    │ 调用 CRUD 方法
    ▼
Repository（持有 ModelContext）
    │ 读写
    ▼
SwiftData（持久化）

─── 状态回流方向 ──────────────────────────────

SwiftData 变更
    │
    ▼
Repository（返回 Result<T, AppError>）
    │
    ▼
Service（业务处理后返回）
    │
    ▼
ViewModel（更新 @Observable 状态属性）
    │ SwiftUI 自动重渲染
    ▼
View（展示最新数据）
```

### 1.5 依赖注入策略

```
BillManagerApp
    │ 创建 ModelContainer
    │ 创建 Repository 实例（注入 modelContext）
    │ 创建 Service 实例（注入 Repository）
    │ 通过 @Environment 或 .environment() 向下注入 Service
    ▼
ContentView → ViewModel（初始化时通过 @Environment 获取 Service）
```

具体实现：
- **Repository**：在 App 启动时初始化，通过 `Environment` Key 注入
- **Service**：依赖 Repository，通过构造器注入
- **ViewModel**：在 View 中用 `@State` 持有，通过 `.init(service:)` 构造

---

## 2. 目录结构设计

```
BillManager/
│
├── App/
│   ├── BillManagerApp.swift         # 应用入口，容器配置，依赖注入根节点
│   └── ContentView.swift            # 根视图（TabView），持有 AppViewModel
│
├── Models/                          # SwiftData @Model 实体（基本不变）
│   ├── Bill.swift                   # 账单模型（将 amount 从 Double 改为 Decimal）
│   ├── Ledger.swift                 # 账本模型
│   ├── Category.swift               # 分类模型
│   └── Statistics.swift             # 统计值对象（纯 struct，非 @Model）
│
├── Repositories/                    # 数据访问层（新增）
│   ├── Protocols/
│   │   ├── BillRepositoryProtocol.swift
│   │   ├── LedgerRepositoryProtocol.swift
│   │   └── CategoryRepositoryProtocol.swift
│   ├── BillRepository.swift
│   ├── LedgerRepository.swift
│   └── CategoryRepository.swift
│
├── Services/                        # 业务服务层（新增）
│   ├── Protocols/
│   │   ├── BillServiceProtocol.swift
│   │   ├── LedgerServiceProtocol.swift
│   │   └── StatisticsServiceProtocol.swift
│   ├── BillService.swift
│   ├── LedgerService.swift
│   └── StatisticsService.swift
│
├── ViewModels/                      # 视图模型层（新增）
│   ├── AppViewModel.swift           # 全局状态（当前账本、Tab 状态）
│   ├── BillListViewModel.swift      # 账单列表页视图模型
│   ├── LedgerListViewModel.swift    # 账本列表页视图模型
│   ├── StatisticsViewModel.swift    # 统计页视图模型
│   ├── AddRecordViewModel.swift     # 快捷记账页视图模型
│   ├── BillEditorViewModel.swift    # 账单编辑页视图模型
│   └── SettingsViewModel.swift      # 设置页视图模型
│
├── Views/                           # 视图层（重构，剥离业务逻辑）
│   ├── Bills/
│   │   ├── BillListView.swift       # 账单列表页（绑定 BillListViewModel）
│   │   └── BillEditorView.swift     # 账单详情/编辑页（绑定 BillEditorViewModel）
│   ├── Ledgers/
│   │   └── LedgerListView.swift     # 账本列表页（绑定 LedgerListViewModel）
│   ├── Records/
│   │   └── AddRecordView.swift      # 快捷记账页（绑定 AddRecordViewModel）
│   ├── Statistics/
│   │   └── StatisticsView.swift     # 统计分析页（绑定 StatisticsViewModel）
│   └── Settings/
│       └── SettingsView.swift       # 设置页（绑定 SettingsViewModel）
│
├── Components/                      # 可复用 UI 组件层（扩充，对应 UI 规范 13 个组件）
│   ├── Buttons/
│   │   ├── PrimaryButton.swift      # 主按钮（规范 6.1）
│   │   └── SecondaryButton.swift    # 次要按钮（规范 6.2）
│   ├── Cards/
│   │   └── CardView.swift           # 通用卡片容器（规范 6.3）
│   ├── Display/
│   │   ├── AmountDisplay.swift      # 金额展示组件（规范 6.4）
│   │   ├── IconBadge.swift          # 图标徽章（规范 6.5）
│   │   └── TagChip.swift            # 标签/分类选择器（规范 6.8）
│   ├── Layout/
│   │   ├── SectionHeader.swift      # 分组标题（规范 6.6）
│   │   └── EmptyStateView.swift     # 空状态视图（规范 6.7）
│   ├── Feedback/
│   │   └── LoadingIndicator.swift   # 加载指示器（规范 6.9）
│   ├── Navigation/
│   │   ├── CustomNavBar.swift       # 自定义导航栏（规范 6.10，重构现有）
│   │   └── BottomTabBar.swift       # 底部标签栏（规范 6.11，重构现有）
│   └── Input/
│       ├── SearchBar.swift          # 搜索栏（规范 6.12）
│       └── DateRangePicker.swift    # 日期范围选择器（规范 6.13）
│
└── Utilities/
    ├── DesignSystem.swift           # 设计系统（扩充色彩/字体/间距/阴影 Token）
    ├── Extensions.swift             # Swift 扩展（保留现有，补充 Decimal 支持）
    ├── Constants.swift              # 全局常量（新增，如 UserDefaults Key）
    └── AppError.swift               # 统一错误类型（新增）
```

---

## 3. 各层详细接口设计

### 3.1 Utilities 层

#### 3.1.1 AppError.swift

```swift
/// 应用统一错误类型，所有层向上传递此错误
enum AppError: LocalizedError {
    // Repository 层错误
    case fetchFailed(String)
    case saveFailed(String)
    case deleteFailed(String)
    case notFound(String)

    // Service 层错误
    case invalidAmount
    case categoryRequired
    case ledgerRequired
    case operationNotAllowed(String)

    // 通用错误
    case unknown(Error)

    var errorDescription: String? { ... }
    var recoverySuggestion: String? { ... }
}
```

#### 3.1.2 Constants.swift

```swift
enum UserDefaultsKeys {
    static let lastSelectedLedgerId = "lastSelectedLedgerId"
    static let defaultCurrency = "defaultCurrency"
    static let dateFormat = "dateFormat"
    static let weekStartDay = "weekStartDay"
}

enum DefaultValues {
    static let currency = "CNY"
    static let dateFormat = "yyyy-MM-dd"
    static let ledgerName = "默认账本"
    static let ledgerIcon = "book.fill"
    static let ledgerColorHex = "#F59E0B"
}
```

#### 3.1.3 DesignSystem.swift（完整扩充版）

```swift
// MARK: - 颜色系统（完整对应 UI 规范 §2）
extension Color {
    // Primary
    static let appPrimary        = Color(hex: "#F59E0B")
    static let appPrimaryLight   = Color(hex: "#FCD34D")
    static let appPrimaryDark    = Color(hex: "#D97706")
    static let appPrimarySurface = Color(hex: "#FFFBEB")   // 新增

    // Semantic
    static let appIncome         = Color(hex: "#10B981")
    static let appIncomeLight    = Color(hex: "#D1FAE5")   // 新增
    static let appExpense        = Color(hex: "#F43F5E")
    static let appExpenseLight   = Color(hex: "#FFE4E8")   // 新增
    static let appSuccess        = Color(hex: "#22C55E")
    static let appWarning        = Color(hex: "#F97316")
    static let appError          = Color(hex: "#EF4444")
    static let appInfo           = Color(hex: "#3B82F6")   // 新增

    // Background
    static let appBackground     = Color(hex: "#FAFAF9")
    static let appBackgroundAlt  = Color(hex: "#F5F5F4")
    static let appCard           = Color.white
    static let appDivider        = Color(hex: "#E7E5E4")   // 新增

    // Text
    static let appTextPrimary    = Color(hex: "#1C1917")
    static let appTextSecondary  = Color(hex: "#78716C")
    static let appTextTertiary   = Color(hex: "#A8A29E")
    static let appPlaceholder    = Color(hex: "#D6D3D1")
    static let appTextOnPrimary  = Color.white             // 新增

    // Warm Accent（新增）
    static let accentCoral       = Color(hex: "#FB923C")
    static let accentRose        = Color(hex: "#FB7185")
    static let accentSand        = Color(hex: "#FDE68A")
    static let accentBrown       = Color(hex: "#92400E")
}

// MARK: - 间距系统（对应 UI 规范 §4.1）
struct AppSpacing {
    static let s1:  CGFloat = 4
    static let s2:  CGFloat = 8
    static let s3:  CGFloat = 12
    static let s4:  CGFloat = 16   // 标准间距
    static let s5:  CGFloat = 20
    static let s6:  CGFloat = 24
    static let s8:  CGFloat = 32
    static let s10: CGFloat = 40
    static let s12: CGFloat = 48
    static let pageHorizontal: CGFloat = 16
}

// MARK: - 圆角系统（对应 UI 规范 §4.2）
struct AppRadius {
    static let xs:   CGFloat = 4
    static let sm:   CGFloat = 8
    static let md:   CGFloat = 12
    static let lg:   CGFloat = 16   // 标准卡片
    static let xl:   CGFloat = 24
    static let xxl:  CGFloat = 32
    static let full: CGFloat = 999
}

// MARK: - 阴影系统（对应 UI 规范 §5，使用暖色调阴影）
extension View {
    func shadowLight() -> some View {
        self.shadow(color: Color(hex: "#92400E").opacity(0.06), radius: 8, x: 0, y: 2)
    }
    func shadowStandard() -> some View {
        self.shadow(color: Color(hex: "#92400E").opacity(0.10), radius: 16, x: 0, y: 4)
    }
    func shadowEmphasis() -> some View {
        self.shadow(color: Color.appPrimary.opacity(0.30), radius: 20, x: 0, y: 8)
    }
}

// MARK: - 主色渐变
struct AppGradient {
    static let primary = LinearGradient(
        colors: [Color.appPrimaryLight, Color.appPrimary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let summaryCard = LinearGradient(
        colors: [Color(hex: "#FFFBEB"), Color(hex: "#FEF3C7")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
```

---

### 3.2 Models 层

Models 层基本保持不变，有以下调整建议：

#### 3.2.1 Bill.swift（调整 amount 类型）

```swift
// 建议将 amount: Double 改为 Decimal，避免浮点精度问题
// 若短期内不做此改动，在 Repository 层做精度处理即可
@Model
final class Bill {
    var id: UUID
    var amount: Decimal          // 从 Double 改为 Decimal（数据迁移注意事项见第7节）
    var typeRawValue: String
    var categoryName: String
    var categoryIcon: String
    var categoryColorHex: String
    var note: String?
    var date: Date
    var createdAt: Date
    var updatedAt: Date
    var ledger: Ledger?
    // ... 其余不变
}
```

#### 3.2.2 Statistics.swift（新增类型）

```swift
// 在现有基础上新增：
struct MonthlySummary {
    var year: Int
    var month: Int
    var totalIncome: Decimal
    var totalExpense: Decimal
    var balance: Decimal
    var billCount: Int
}

// TimeRange 补充方法
extension TimeRange {
    /// 返回指定年月的日期范围
    static func month(year: Int, month: Int) -> (start: Date, end: Date) { ... }
    /// 返回当前时间段的显示标题（如"2026年3月"）
    var navigationTitle: String { ... }
}
```

---

### 3.3 Repositories 层

#### 3.3.1 BillRepositoryProtocol.swift

```swift
protocol BillRepositoryProtocol {
    // MARK: - 查询
    /// 查询指定账本在时间范围内的所有账单（按日期倒序）
    func fetchBills(for ledger: Ledger, in range: TimeRange) throws -> [Bill]

    /// 查询指定账本在指定月份的账单
    func fetchBills(for ledger: Ledger, year: Int, month: Int) throws -> [Bill]

    /// 全文搜索账单（按 categoryName、note 匹配）
    func searchBills(in ledger: Ledger, keyword: String) throws -> [Bill]

    /// 按类型查询账单
    func fetchBills(for ledger: Ledger, type: BillType, in range: TimeRange) throws -> [Bill]

    // MARK: - 写入
    /// 创建并插入新账单
    @discardableResult
    func createBill(
        amount: Decimal,
        type: BillType,
        category: Category,
        note: String?,
        date: Date,
        in ledger: Ledger
    ) throws -> Bill

    /// 更新账单字段
    func updateBill(
        _ bill: Bill,
        amount: Decimal,
        type: BillType,
        category: Category,
        note: String?,
        date: Date
    ) throws

    /// 删除账单
    func deleteBill(_ bill: Bill) throws

    /// 批量删除账单
    func deleteBills(_ bills: [Bill]) throws
}
```

#### 3.3.2 LedgerRepositoryProtocol.swift

```swift
protocol LedgerRepositoryProtocol {
    // MARK: - 查询
    /// 获取所有未归档账本（按创建时间倒序）
    func fetchActiveLedgers() throws -> [Ledger]

    /// 获取所有已归档账本
    func fetchArchivedLedgers() throws -> [Ledger]

    /// 通过 ID 查询账本
    func fetchLedger(by id: UUID) throws -> Ledger?

    // MARK: - 写入
    /// 创建新账本
    @discardableResult
    func createLedger(name: String, icon: String, colorHex: String) throws -> Ledger

    /// 更新账本信息
    func updateLedger(_ ledger: Ledger, name: String, icon: String, colorHex: String) throws

    /// 归档账本
    func archiveLedger(_ ledger: Ledger) throws

    /// 恢复已归档账本
    func restoreLedger(_ ledger: Ledger) throws

    /// 删除账本（及其下所有账单和分类，通过 SwiftData cascade 规则）
    func deleteLedger(_ ledger: Ledger) throws
}
```

#### 3.3.3 CategoryRepositoryProtocol.swift

```swift
protocol CategoryRepositoryProtocol {
    // MARK: - 查询
    /// 获取指定账本、指定类型的分类列表
    func fetchCategories(for ledger: Ledger, type: BillType) throws -> [Category]

    /// 获取指定账本的所有分类
    func fetchAllCategories(for ledger: Ledger) throws -> [Category]

    // MARK: - 写入
    /// 创建分类
    @discardableResult
    func createCategory(
        name: String,
        icon: String,
        colorHex: String,
        type: BillType,
        in ledger: Ledger
    ) throws -> Category

    /// 更新分类
    func updateCategory(_ category: Category, name: String, icon: String, colorHex: String) throws

    /// 删除分类
    func deleteCategory(_ category: Category) throws

    /// 批量创建默认分类（初始化账本时调用）
    func createDefaultCategories(for ledger: Ledger) throws
}
```

#### 3.3.4 Repository 实现类（以 BillRepository 为例）

```swift
final class BillRepository: BillRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchBills(for ledger: Ledger, in range: TimeRange) throws -> [Bill] {
        let (startDate, endDate) = range.dateRange()
        let ledgerId = ledger.id
        let descriptor = FetchDescriptor<Bill>(
            predicate: #Predicate { bill in
                bill.ledger?.id == ledgerId &&
                bill.date >= startDate &&
                bill.date <= endDate
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func createBill(
        amount: Decimal,
        type: BillType,
        category: Category,
        note: String?,
        date: Date,
        in ledger: Ledger
    ) throws -> Bill {
        let bill = Bill(
            amount: amount,
            type: type,
            categoryName: category.name,
            categoryIcon: category.icon,
            categoryColorHex: category.colorHex,
            note: note,
            date: date
        )
        bill.ledger = ledger
        modelContext.insert(bill)
        try modelContext.save()
        return bill
    }

    func deleteBill(_ bill: Bill) throws {
        modelContext.delete(bill)
        try modelContext.save()
    }

    // ... 其他方法实现
}
```

---

### 3.4 Services 层

#### 3.4.1 BillServiceProtocol.swift

```swift
protocol BillServiceProtocol {
    /// 添加一条账单（包含输入验证）
    func addBill(
        amount: Decimal,
        type: BillType,
        category: Category,
        note: String?,
        date: Date,
        to ledger: Ledger
    ) async throws -> Bill

    /// 更新账单
    func updateBill(
        _ bill: Bill,
        amount: Decimal,
        type: BillType,
        category: Category,
        note: String?,
        date: Date
    ) async throws

    /// 删除账单
    func deleteBill(_ bill: Bill) async throws

    /// 获取账单列表（支持筛选）
    func fetchBills(
        for ledger: Ledger,
        in range: TimeRange,
        type: BillType?,
        searchKeyword: String?
    ) async throws -> [Bill]

    /// 获取月度账单（用于账单列表页）
    func fetchMonthlyBills(for ledger: Ledger, year: Int, month: Int) async throws -> [Bill]
}
```

#### 3.4.2 LedgerServiceProtocol.swift

```swift
protocol LedgerServiceProtocol {
    /// 创建账本（自动初始化默认分类）
    func createLedger(name: String, icon: String, colorHex: String) async throws -> Ledger

    /// 更新账本信息
    func updateLedger(_ ledger: Ledger, name: String, icon: String, colorHex: String) async throws

    /// 归档账本
    func archiveLedger(_ ledger: Ledger) async throws

    /// 恢复账本
    func restoreLedger(_ ledger: Ledger) async throws

    /// 删除账本（含二次确认语义，实际删除由 Repository 执行）
    func deleteLedger(_ ledger: Ledger) async throws

    /// 获取活跃账本列表
    func fetchActiveLedgers() async throws -> [Ledger]

    /// 获取归档账本列表
    func fetchArchivedLedgers() async throws -> [Ledger]

    /// 初始化默认账本（App 首次启动时调用）
    func initializeDefaultLedgerIfNeeded() async throws

    /// 获取或恢复上次选中的账本
    func resolveCurrentLedger(from ledgers: [Ledger]) -> Ledger?
}
```

#### 3.4.3 StatisticsServiceProtocol.swift

```swift
protocol StatisticsServiceProtocol {
    /// 计算指定账本在时间范围内的统计数据（含收支总额、分类明细、日趋势）
    func calculateStatistics(
        for ledger: Ledger,
        in range: TimeRange,
        type: BillType
    ) async throws -> Statistics

    /// 计算月度汇总（账单列表页顶部汇总卡片）
    func calculateMonthlySummary(
        for ledger: Ledger,
        year: Int,
        month: Int
    ) async throws -> MonthlySummary

    /// 获取分类占比统计
    func calculateCategoryStats(
        for bills: [Bill],
        type: BillType
    ) -> [CategoryStat]

    /// 获取日趋势统计
    func calculateDailyTrend(
        for bills: [Bill],
        from startDate: Date,
        to endDate: Date
    ) -> [DailyStat]
}
```

#### 3.4.4 Service 实现类（以 StatisticsService 为例）

```swift
final class StatisticsService: StatisticsServiceProtocol {
    private let billRepository: BillRepositoryProtocol

    init(billRepository: BillRepositoryProtocol) {
        self.billRepository = billRepository
    }

    func calculateStatistics(
        for ledger: Ledger,
        in range: TimeRange,
        type: BillType
    ) async throws -> Statistics {
        let bills = try billRepository.fetchBills(for: ledger, type: type, in: range)
        let totalAmount = bills.reduce(Decimal(0)) { $0 + $1.amount }
        let allBills = try billRepository.fetchBills(for: ledger, in: range)
        let totalIncome = allBills.filter { $0.type == .income }.reduce(Decimal(0)) { $0 + $1.amount }
        let totalExpense = allBills.filter { $0.type == .expense }.reduce(Decimal(0)) { $0 + $1.amount }

        let categoryStats = calculateCategoryStats(for: bills, type: type)
        let (startDate, endDate) = range.dateRange()
        let dailyTrend = calculateDailyTrend(for: allBills, from: startDate, to: endDate)

        return Statistics(
            totalIncome: totalIncome,
            totalExpense: totalExpense,
            categoryBreakdown: categoryStats,
            dailyTrend: dailyTrend
        )
    }

    func calculateCategoryStats(for bills: [Bill], type: BillType) -> [CategoryStat] {
        let filtered = bills.filter { $0.type == type }
        let totalAmount = filtered.reduce(Decimal(0)) { $0 + $1.amount }
        let grouped = Dictionary(grouping: filtered) { $0.categoryName }

        return grouped.map { (name, bills) in
            let amount = bills.reduce(Decimal(0)) { $0 + $1.amount }
            let percentage = totalAmount > 0 ? Double(truncating: (amount / totalAmount * 100) as NSDecimalNumber) : 0
            let first = bills.first!
            return CategoryStat(
                categoryName: name,
                icon: first.categoryIcon,
                colorHex: first.categoryColorHex,
                amount: amount,
                percentage: percentage,
                type: type
            )
        }
        .sorted { $0.amount > $1.amount }
    }
    // ... 其他方法实现
}
```

---

### 3.5 ViewModels 层

所有 ViewModel 使用 Swift `@Observable` 宏（iOS 17+），不使用 `ObservableObject`。

#### 3.5.1 AppViewModel.swift

```swift
/// 全局应用状态，通过 @Environment 在全应用共享
@Observable
final class AppViewModel {
    // MARK: - State
    var currentLedger: Ledger?
    var selectedTab: Int = 0
    var isShowingAddRecord: Bool = false

    // MARK: - Dependencies
    private let ledgerService: LedgerServiceProtocol

    init(ledgerService: LedgerServiceProtocol) {
        self.ledgerService = ledgerService
    }

    // MARK: - Methods
    func selectLedger(_ ledger: Ledger)
    func onAppLaunch(availableLedgers: [Ledger]) async
    func resolveCurrentLedger(from ledgers: [Ledger])
}
```

#### 3.5.2 BillListViewModel.swift

```swift
@Observable
final class BillListViewModel {
    // MARK: - State（View 直接绑定）
    var bills: [Bill] = []
    var groupedBills: [(date: Date, bills: [Bill])] = []
    var monthlySummary: MonthlySummary = .empty
    var isLoading: Bool = false
    var error: AppError? = nil
    var searchText: String = ""
    var selectedCategory: Category? = nil
    var currentYear: Int = Calendar.current.component(.year, from: Date())
    var currentMonth: Int = Calendar.current.component(.month, from: Date())

    // MARK: - Dependencies
    private let billService: BillServiceProtocol
    private let statisticsService: StatisticsServiceProtocol
    let ledger: Ledger

    init(ledger: Ledger, billService: BillServiceProtocol, statisticsService: StatisticsServiceProtocol)

    // MARK: - Methods
    func loadBills() async
    func navigateToPreviousMonth()
    func navigateToNextMonth()
    func deleteBill(_ bill: Bill) async
    func refreshData() async

    // MARK: - Computed（格式化后供 View 使用）
    var monthTitle: String         // "2026年3月"
    var canNavigateForward: Bool   // 不超过当前月
    var filteredBills: [Bill]      // 根据 searchText 和 selectedCategory 过滤
}
```

#### 3.5.3 StatisticsViewModel.swift

```swift
@Observable
final class StatisticsViewModel {
    // MARK: - State
    var statistics: Statistics = .empty
    var selectedTimeRange: TimeRange = .month
    var selectedBillType: BillType = .expense
    var isLoading: Bool = false
    var error: AppError? = nil

    // MARK: - Dependencies
    private let statisticsService: StatisticsServiceProtocol
    var currentLedger: Ledger?

    init(statisticsService: StatisticsServiceProtocol)

    // MARK: - Methods
    func loadStatistics() async
    func selectTimeRange(_ range: TimeRange) async
    func selectBillType(_ type: BillType) async
    func setLedger(_ ledger: Ledger) async

    // MARK: - Computed
    var totalAmountFormatted: String
    var billCountText: String
    var categoryStats: [CategoryStat]    // 由 statistics 派生
    var dailyStats: [DailyStat]          // 由 statistics 派生
}
```

#### 3.5.4 AddRecordViewModel.swift

```swift
@Observable
final class AddRecordViewModel {
    // MARK: - State
    var amountText: String = ""
    var selectedBillType: BillType = .expense
    var selectedCategory: Category? = nil
    var note: String = ""
    var selectedDate: Date = Date()
    var availableCategories: [Category] = []
    var isSaving: Bool = false
    var saveSuccess: Bool = false
    var error: AppError? = nil

    // MARK: - Validation
    var canSave: Bool                    // amount > 0 && category != nil
    var amountValidationError: String?   // 实时验证错误信息

    // MARK: - Dependencies
    private let billService: BillServiceProtocol
    private let categoryRepository: CategoryRepositoryProtocol
    let ledger: Ledger

    init(ledger: Ledger, billService: BillServiceProtocol, categoryRepository: CategoryRepositoryProtocol)

    // MARK: - Methods
    func loadCategories() async
    func selectBillType(_ type: BillType) async   // 切换类型时重新加载分类
    func saveRecord() async
    func reset()
}
```

#### 3.5.5 BillEditorViewModel.swift

```swift
@Observable
final class BillEditorViewModel {
    // MARK: - State
    var isEditMode: Bool = false
    var amountText: String = ""
    var selectedBillType: BillType = .expense
    var selectedCategory: Category? = nil
    var note: String = ""
    var selectedDate: Date = Date()
    var availableCategories: [Category] = []
    var isSaving: Bool = false
    var isDeletingConfirmationShowing: Bool = false
    var error: AppError? = nil

    // MARK: - Readonly（只读展示）
    let bill: Bill?                      // nil 表示新建
    var isNewBill: Bool { bill == nil }
    var canSave: Bool

    // MARK: - Dependencies
    private let billService: BillServiceProtocol
    private let categoryRepository: CategoryRepositoryProtocol
    let ledger: Ledger

    init(bill: Bill?, ledger: Ledger, preSelectedType: BillType, billService: BillServiceProtocol, categoryRepository: CategoryRepositoryProtocol)

    // MARK: - Methods
    func enterEditMode()
    func cancelEdit()
    func saveChanges() async
    func deleteBill() async
    func loadCategories() async
}
```

#### 3.5.6 LedgerListViewModel.swift

```swift
@Observable
final class LedgerListViewModel {
    // MARK: - State
    var activeLedgers: [Ledger] = []
    var archivedLedgers: [Ledger] = []
    var isLoading: Bool = false
    var error: AppError? = nil
    var showingDeleteAlert: Bool = false
    var ledgerToDelete: Ledger? = nil

    // MARK: - Dependencies
    private let ledgerService: LedgerServiceProtocol

    init(ledgerService: LedgerServiceProtocol)

    // MARK: - Methods
    func loadLedgers() async
    func createLedger(name: String, icon: String, colorHex: String) async
    func updateLedger(_ ledger: Ledger, name: String, icon: String, colorHex: String) async
    func archiveLedger(_ ledger: Ledger) async
    func restoreLedger(_ ledger: Ledger) async
    func confirmDelete(_ ledger: Ledger)
    func executeDelete() async
}
```

#### 3.5.7 SettingsViewModel.swift

```swift
@Observable
final class SettingsViewModel {
    // MARK: - State
    var defaultCurrency: String = UserDefaults.standard.string(forKey: UserDefaultsKeys.defaultCurrency) ?? DefaultValues.currency
    var dateFormat: String = UserDefaults.standard.string(forKey: UserDefaultsKeys.dateFormat) ?? DefaultValues.dateFormat
    var isExporting: Bool = false
    var showingClearConfirm: Bool = false
    var error: AppError? = nil

    // MARK: - Readonly
    var appVersion: String
    var currentLedger: Ledger?

    // MARK: - Dependencies
    private let ledgerService: LedgerServiceProtocol

    init(ledgerService: LedgerServiceProtocol)

    // MARK: - Methods
    func updateCurrency(_ currency: String)
    func updateDateFormat(_ format: String)
    func exportData() async
    func clearAllData() async
}
```

---

## 4. 关键流程设计

### 4.1 添加账单流程

```
用户操作: 在 AddRecordView 点击"保存"
    │
    ▼
AddRecordView.saveButtonTapped()
    │ 调用
    ▼
AddRecordViewModel.saveRecord()
    │ 验证 canSave == true
    │ 设置 isSaving = true
    │ 调用
    ▼
BillService.addBill(amount:type:category:note:date:to:)
    │ 验证金额 > 0
    │ 验证 category 不为 nil
    │ 调用
    ▼
BillRepository.createBill(amount:type:category:note:date:in:)
    │ 构建 Bill 实体
    │ bill.ledger = ledger
    │ modelContext.insert(bill)
    │ try modelContext.save()
    │ 返回 Bill
    ▼
BillService 返回 Bill
    ▼
AddRecordViewModel
    │ 设置 isSaving = false
    │ 设置 saveSuccess = true（触发 Toast）
    │ 触发 dismiss
    ▼
BillListViewModel（监听数据变化，自动刷新）
    │ 调用 loadBills() 重新加载
    ▼
BillListView 自动重渲染（@Observable 驱动）

异常分支:
Repository 抛出错误
    → Service 包装为 AppError 向上传递
    → ViewModel 捕获，设置 error: AppError?
    → View 监听 error，展示 Alert 或 Toast
```

### 4.2 统计数据查询流程

```
用户操作: 切换时间范围（周/月/年）
    │
    ▼
StatisticsView → DateRangePicker 回调
    │ 调用
    ▼
StatisticsViewModel.selectTimeRange(_ range: TimeRange)
    │ 设置 selectedTimeRange = range
    │ 设置 isLoading = true
    │ 调用
    ▼
StatisticsService.calculateStatistics(for:in:type:)
    │ 调用 BillRepository.fetchBills(for:type:in:)
    │     └── 执行 SwiftData FetchDescriptor 查询
    │ 调用 calculateCategoryStats(for:type:)
    │     └── 按分类分组，计算金额和占比
    │ 调用 calculateDailyTrend(for:from:to:)
    │     └── 按日期遍历，统计每日收支
    │ 返回 Statistics 结构体
    ▼
StatisticsViewModel
    │ 设置 statistics = 返回值
    │ 设置 isLoading = false
    ▼
StatisticsView 自动重渲染
    │ pieChartSection 从 viewModel.categoryStats 读取
    │ trendChartSection 从 viewModel.dailyStats 读取
    │ summaryCard 从 viewModel.statistics 读取
```

### 4.3 账本切换流程

```
用户操作: 在 BillListView 导航栏点击账本名称
    │
    ▼
账本选择 Sheet 弹出（由 AppViewModel.isShowingLedgerPicker 控制）
    │
用户选择账本
    │
    ▼
AppViewModel.selectLedger(_ ledger: Ledger)
    │ 设置 currentLedger = ledger
    │ 持久化到 UserDefaults（key: lastSelectedLedgerId）
    ▼
BillListView 监听 appViewModel.currentLedger 变化
    │ 重新创建/更新 BillListViewModel（传入新 ledger）
    ▼
BillListViewModel.loadBills() 自动触发
    │ 加载新账本的账单数据
    ▼
BillListView 展示新账本数据（带切换动画 .easeInOut(duration: 0.3)）

同步: StatisticsView 也通过 AppViewModel.currentLedger 获取当前账本
      → StatisticsViewModel.setLedger() 同步更新
```

### 4.4 应用冷启动流程

```
BillManagerApp.init()
    │ 创建 ModelContainer（schema: [Ledger, Bill, Category]）
    │ 创建 modelContext = container.mainContext
    │ 创建 BillRepository(modelContext:)
    │ 创建 CategoryRepository(modelContext:)
    │ 创建 LedgerRepository(modelContext:)
    │ 创建 BillService(billRepository:)
    │ 创建 LedgerService(ledgerRepository:, categoryRepository:)
    │ 创建 StatisticsService(billRepository:)
    │ 创建 AppViewModel(ledgerService:)
    │ 通过 .environment() 注入到视图树
    ▼
ContentView.onAppear
    │ 调用 AppViewModel.onAppLaunch(availableLedgers:)
    ▼
LedgerService.initializeDefaultLedgerIfNeeded()
    │ 检查 LedgerRepository.fetchActiveLedgers()
    │ 若为空: 创建默认账本 + 默认分类
    │ 通过 UserDefaults 恢复上次选中账本
    ▼
AppViewModel.currentLedger 设置完成
    ▼
所有依赖 currentLedger 的 ViewModel 开始加载数据
```

---

## 5. Components 层设计

对应 UI 设计规范第 6 节的 13 个组件，每个组件定义如下：

### 5.1 组件总表

| # | 文件名 | 组件名 | 对应规范 | 所在子目录 |
|---|--------|--------|---------|-----------|
| 1 | PrimaryButton.swift | `PrimaryButton` | §6.1 | Components/Buttons/ |
| 2 | SecondaryButton.swift | `SecondaryButton` | §6.2 | Components/Buttons/ |
| 3 | CardView.swift | `CardView<Content>` | §6.3 | Components/Cards/ |
| 4 | AmountDisplay.swift | `AmountDisplay` | §6.4 | Components/Display/ |
| 5 | IconBadge.swift | `IconBadge` | §6.5 | Components/Display/ |
| 6 | SectionHeader.swift | `SectionHeader` | §6.6 | Components/Layout/ |
| 7 | EmptyStateView.swift | `EmptyStateView` | §6.7 | Components/Layout/ |
| 8 | TagChip.swift | `TagChip` | §6.8 | Components/Display/ |
| 9 | LoadingIndicator.swift | `LoadingIndicator` | §6.9 | Components/Feedback/ |
| 10 | CustomNavBar.swift | `CustomNavBar` | §6.10 | Components/Navigation/ |
| 11 | BottomTabBar.swift | `BottomTabBar` | §6.11 | Components/Navigation/ |
| 12 | SearchBar.swift | `SearchBar` | §6.12 | Components/Input/ |
| 13 | DateRangePicker.swift | `DateRangePicker` | §6.13 | Components/Input/ |

### 5.2 各组件接口定义

#### PrimaryButton.swift

```swift
enum ButtonStyleType { case full, fixed(width: CGFloat) }
enum ButtonSizeType { case standard, compact }

struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var style: ButtonStyleType = .full
    var size: ButtonSizeType = .standard
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void
    // 高度: standard=52pt, compact=44pt
    // 背景: AppGradient.primary，圆角 AppRadius.full
    // 阴影: shadowEmphasis()
    // 按下缩放: 0.97，禁用透明度: 0.4
}

// 使用示例:
// PrimaryButton(title: "保存账单", icon: "checkmark") { viewModel.saveRecord() }
// 使用场景: AddRecordView 保存按钮、LedgerEditorView 确认按钮
```

#### SecondaryButton.swift

```swift
enum SecondaryButtonVariant { case outlined, filled }

struct SecondaryButton: View {
    let title: String
    var icon: String? = nil
    var variant: SecondaryButtonVariant = .outlined
    var size: ButtonSizeType = .standard
    var isDisabled: Bool = false
    let action: () -> Void
    // outlined: appPrimary 描边，透明背景
    // filled: appPrimarySurface 背景
    // 文字颜色: appPrimary
}

// 使用场景: BillEditorView 取消按钮、各 Sheet 取消操作
```

#### CardView.swift

```swift
enum ShadowLevel { case none, light, standard }

struct CardView<Content: View>: View {
    var padding: CGFloat = AppSpacing.s4
    var cornerRadius: CGFloat = AppRadius.lg
    var shadowLevel: ShadowLevel = .light
    var hasBorder: Bool = false
    @ViewBuilder let content: () -> Content
    // 背景: appCard (white)
    // 可选描边: appDivider 0.5pt
}

// 使用场景: 月度汇总卡片、统计卡片、设置分组、账本卡片
```

#### AmountDisplay.swift

```swift
enum AmountType { case income, expense, balance, neutral }
enum AmountSize {
    case large    // 40pt Heavy Rounded（首页汇总）
    case medium   // 22pt Semibold（列表汇总）
    case small    // 16pt Semibold（列表行）
    case micro    // 12pt Medium（徽章内）
}

struct AmountDisplay: View {
    let amount: Decimal
    let type: AmountType
    var size: AmountSize = .small
    var showSign: Bool = false
    var currencyCode: String = "CNY"
    // 颜色: income=appIncome, expense=appExpense, balance=appPrimary, neutral=appTextPrimary
    // 字体: SF Pro Rounded + monospacedDigit()
    // 格式: ¥1,234.56（千分位，两位小数）
}

// 使用场景: BillRow 金额列、统计汇总卡片、账本卡片收支展示
```

#### IconBadge.swift

```swift
enum BadgeSize {
    case xs   // 24pt，图标12pt
    case sm   // 32pt，图标16pt
    case md   // 44pt，图标22pt（标准）
    case lg   // 60pt，图标28pt（账本封面）
}
enum BadgeShape { case circle, roundedSquare }

struct IconBadge: View {
    let iconName: String
    let backgroundColor: Color
    let iconColor: Color
    var size: BadgeSize = .md
    var shape: BadgeShape = .roundedSquare
}

// 使用场景: 账本列表图标、分类选择网格、账单行分类标识
```

#### SectionHeader.swift

```swift
struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var actionTitle: String? = nil
    var showAccentBar: Bool = false
    var action: (() -> Void)? = nil
    // 标题: 16pt Semibold appTextPrimary
    // 操作文字: 14pt Regular appPrimary
    // 装饰线: 3×18pt 圆角矩形，appPrimary 色
}

// 使用场景: 账单列表日期分组头、统计页分类区块、设置页分组标题
```

#### EmptyStateView.swift

```swift
struct EmptyStateView: View {
    var iconName: String = "tray.fill"
    let title: String
    var subtitle: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    // 图标: 80pt，appPlaceholder 色
    // 主文案: 18pt Semibold，appTextSecondary
    // 副文案: 14pt Regular，appTextTertiary
    // 操作按钮: PrimaryButton compact
}

// 使用场景: 空账本列表、无账单时、统计页无数据
```

#### TagChip.swift

```swift
enum ChipStyle { case `default`, selected, highlighted }
enum ChipSize { case standard, compact }

struct TagChip: View {
    let title: String
    var iconName: String? = nil
    var style: ChipStyle = .default
    var size: ChipSize = .standard
    var onTap: (() -> Void)? = nil
    // standard: 高度32pt，compact: 28pt
    // 内边距: 水平12pt，垂直6pt
    // 圆角: AppRadius.full
    // 字号: 13pt Medium
    // default: appBackgroundAlt背景，selected: appPrimary背景+白色文字
}

// 使用场景: 账单分类筛选横向滚动列表、账单类型切换（收入/支出）
```

#### LoadingIndicator.swift

```swift
enum LoadingStyle { case inline, overlay }

struct LoadingIndicator: View {
    var style: LoadingStyle = .inline
    var message: String? = nil
    // inline: 16pt ProgressView，appPrimary 色
    // overlay: 80×80pt 白色卡片 + 32pt spinner + 说明文字 + 毛玻璃背景
    // 动画: fade 0.2s
}

// 使用场景: 账单保存中、数据导出中、账本切换加载
```

#### CustomNavBar.swift（重构现有）

```swift
enum NavBarStyle { case standard, largeTitle }

struct NavBarItem {
    let icon: String?
    let title: String?
    let action: () -> Void
}

struct CustomNavBar: View {
    let title: String
    var style: NavBarStyle = .standard
    var leftItem: NavBarItem? = nil
    var rightItems: [NavBarItem] = []
    var isScrolled: Bool = false   // 由外部传入，控制分隔线和背景状态
    // 高度: standard=44pt, largeTitle=56pt
    // 背景: 未滚动透明，滚动后 appCard + shadowLight()
    // 分隔线: 滚动后显示 0.5pt appDivider
}

// 相比现有实现的主要变化:
// 1. 增加 NavBarStyle 支持大标题模式
// 2. 增加 isScrolled 参数，实现滚动感知效果
// 3. 规范化右侧按钮为 [NavBarItem] 数组
```

#### BottomTabBar.swift（重构现有）

```swift
struct BottomTabBar: View {
    @Binding var selectedTab: Int
    let onAddRecord: () -> Void   // FAB 按钮回调
    // FAB: 56×56pt 圆形，主色渐变，shadowEmphasis()
    // Tab: 3个（账单/统计/设置），激活色 appPrimary
    // 激活指示器: Tab 图标上方 2×16pt 圆角矩形，spring 动画
    // 背景: appCard + 顶部 0.5pt appDivider 分隔线 + 向上 shadowLight()
}

// 相比现有实现的主要变化:
// 1. 增加 FAB 浮动记账按钮（onAddRecord 回调）
// 2. 统一 Tab 激活色为 appPrimary（规范要求），去除各 Tab 不同颜色
// 3. 增加激活指示器动画
```

#### SearchBar.swift

```swift
struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "搜索账单..."
    var onSubmit: (() -> Void)? = nil
    // 背景: appBackgroundAlt，圆角 AppRadius.full，高度 40pt
    // 左侧: 16pt magnifyingglass，appTextTertiary
    // 清除按钮: 有内容时出现，xmark.circle.fill
    // 聚焦动画: appPrimary 1.5pt 描边，0.2s ease
    // 取消按钮: 聚焦时从右侧滑入
}

// 使用场景: BillListView 账单搜索
```

#### DateRangePicker.swift

```swift
struct DateRangePicker: View {
    @Binding var selection: TimeRange
    // 选项: .week / .month / .year（3段）
    // 外观: 胶囊形分段控制器
    // 整体背景: appBackgroundAlt，AppRadius.full
    // 选中段: 白色滑块 + shadowLight()，matchedGeometryEffect 流畅切换
    // 高度: 36pt
    // 文字: 14pt Medium，非选中 appTextSecondary，选中 appTextPrimary
}

// 使用场景: StatisticsView 时间范围切换
```

---

## 6. 重构开发任务拆分

> 按依赖顺序排列，前置 Phase 必须完成后才能开始后续 Phase。
> 同一 Phase 内的任务可并行开发。
> 每个任务预估包含单元测试编写时间。

---

### Phase 0：基础设施（无依赖，最先执行）

**目标**: 建立支撑整个重构的基础代码骨架，所有后续任务依赖此阶段完成。

#### Task 0.1：更新 DesignSystem.swift
- **文件**: `BillManager/Utilities/DesignSystem.swift`
- **内容**: 补全 UI 规范要求的所有色彩/圆角/间距/阴影 Token（参见 §3.1.3 完整定义）
- **删除**: 现有的 `AppColors`、`AppCornerRadius`、`AppShadows` 结构体（迁移到新 API）
- **新增**: `AppSpacing`、`AppRadius`、`AppGradient`、View 阴影扩展
- **注意**: 需要同步更新所有引用旧 API 的地方（全局搜索 `AppColors.` / `AppCornerRadius.`）
- **验收**: 所有现有视图编译通过，颜色显示与规范一致

#### Task 0.2：创建目录结构和基础文件
- **内容**: 按照 §2 目录结构创建所有目录和空文件
- **新增文件**:
  - `BillManager/Utilities/AppError.swift`
  - `BillManager/Utilities/Constants.swift`
  - `BillManager/Repositories/Protocols/` 目录及3个 Protocol 文件
  - `BillManager/Services/Protocols/` 目录及3个 Protocol 文件
  - `BillManager/ViewModels/` 目录及6个 ViewModel 文件（骨架）
- **验收**: 项目编译通过，Xcode 目录树结构正确

---

### Phase 1：数据层（依赖 Phase 0）

**目标**: 实现完整的 Repository 层，所有 SwiftData 操作集中在此层。

#### Task 1.1：实现 LedgerRepository
- **文件**:
  - `BillManager/Repositories/Protocols/LedgerRepositoryProtocol.swift`
  - `BillManager/Repositories/LedgerRepository.swift`
- **实现方法**: 参见 §3.3.2 完整接口
- **关键点**:
  - 使用 `FetchDescriptor` 替代 `@Query`
  - `fetchActiveLedgers()` 需按 `createdAt` 倒序
  - 所有抛出错误包装为 `AppError`
- **测试**: `BillManagerTests/Repositories/LedgerRepositoryTests.swift`

#### Task 1.2：实现 BillRepository
- **文件**:
  - `BillManager/Repositories/Protocols/BillRepositoryProtocol.swift`
  - `BillManager/Repositories/BillRepository.swift`
- **实现方法**: 参见 §3.3.1 完整接口
- **关键点**:
  - `fetchBills(for:in:)` 使用 `FetchDescriptor` 带 Predicate 过滤
  - `searchBills` 使用 `#Predicate` 做 contains 匹配（注意 SwiftData Predicate 的字符串搜索限制）
  - 创建账单时需正确设置 `bill.ledger = ledger`
- **测试**: `BillManagerTests/Repositories/BillRepositoryTests.swift`

#### Task 1.3：实现 CategoryRepository
- **文件**:
  - `BillManager/Repositories/Protocols/CategoryRepositoryProtocol.swift`
  - `BillManager/Repositories/CategoryRepository.swift`
- **实现方法**: 参见 §3.3.3 完整接口
- **关键点**:
  - `createDefaultCategories(for:)` 统一化现有散落于 `ContentView` 和 `LedgerListView` 的重复逻辑
  - 默认分类数据定义为常量，放入 `Constants.swift`
- **测试**: `BillManagerTests/Repositories/CategoryRepositoryTests.swift`

---

### Phase 2：业务服务层（依赖 Phase 1）

**目标**: 实现业务规则封装，剥离视图中的计算逻辑。

#### Task 2.1：实现 StatisticsService
- **文件**:
  - `BillManager/Services/Protocols/StatisticsServiceProtocol.swift`
  - `BillManager/Services/StatisticsService.swift`
- **实现方法**: 参见 §3.4.3 完整接口
- **关键点**:
  - 将 `StatisticsView` 中现有的 `categoryStats` 和 `dailyStats` 计算逻辑迁移至此
  - `calculateDailyTrend` 需处理时间范围内无账单日期的情况（补零）
  - `calculateMonthlySummary` 用于账单列表页月度汇总卡片
- **测试**: `BillManagerTests/Services/StatisticsServiceTests.swift`（重点测试算法正确性）

#### Task 2.2：实现 LedgerService
- **文件**:
  - `BillManager/Services/Protocols/LedgerServiceProtocol.swift`
  - `BillManager/Services/LedgerService.swift`
- **实现方法**: 参见 §3.4.2 完整接口
- **关键点**:
  - `initializeDefaultLedgerIfNeeded()` 合并 `ContentView` 和 `LedgerListView` 中的重复逻辑
  - `resolveCurrentLedger` 读取 `UserDefaults.lastSelectedLedgerId`，使用 `Constants.UserDefaultsKeys.lastSelectedLedgerId`
  - `createLedger` 内部自动调用 `categoryRepository.createDefaultCategories`
- **测试**: `BillManagerTests/Services/LedgerServiceTests.swift`

#### Task 2.3：实现 BillService
- **文件**:
  - `BillManager/Services/Protocols/BillServiceProtocol.swift`
  - `BillManager/Services/BillService.swift`
- **实现方法**: 参见 §3.4.1 完整接口
- **关键点**:
  - `addBill` 中验证 `amount > 0`，否则抛出 `AppError.invalidAmount`
  - `fetchBills` 支持 `searchKeyword` 参数，为 nil 时不过滤
  - 需处理 `amount` 从字符串到 `Decimal` 的转换（建议在 ViewModel 层转换）
- **测试**: `BillManagerTests/Services/BillServiceTests.swift`

---

### Phase 3：组件层（依赖 Phase 0，可与 Phase 1/2 并行）

**目标**: 实现 UI 规范要求的 13 个可复用组件。

#### Task 3.1：PrimaryButton + SecondaryButton
- **文件**: `Components/Buttons/PrimaryButton.swift`, `SecondaryButton.swift`
- **验收**: 在 Xcode Preview 中对比 UI 规范截图，视觉完全一致

#### Task 3.2：CardView
- **文件**: `Components/Cards/CardView.swift`
- **验收**: 支持三种阴影级别，圆角参数正确传入

#### Task 3.3：AmountDisplay
- **文件**: `Components/Display/AmountDisplay.swift`
- **关键点**:
  - 金额格式化使用 `NumberFormatter`，支持千分位和货币符号
  - 字体必须使用 `.system(design: .rounded)` + `.monospacedDigit()`
- **验收**: 四种尺寸在 Preview 中显示正确

#### Task 3.4：IconBadge + TagChip
- **文件**: `Components/Display/IconBadge.swift`, `Components/Display/TagChip.swift`

#### Task 3.5：SectionHeader + EmptyStateView
- **文件**: `Components/Layout/SectionHeader.swift`, `Components/Layout/EmptyStateView.swift`
- **关键点**: `EmptyStateView` 中的操作按钮使用 `PrimaryButton` 组件（依赖 Task 3.1）

#### Task 3.6：LoadingIndicator
- **文件**: `Components/Feedback/LoadingIndicator.swift`
- **关键点**: overlay 样式需使用 `.ultraThinMaterial` 毛玻璃背景

#### Task 3.7：CustomNavBar（重构现有）
- **文件**: `Components/Navigation/CustomNavBar.swift`
- **关键点**:
  - 保留现有 `NavBarButton` 和 `NavBarMenuButton` 子组件
  - 新增 `NavBarStyle` 支持大标题模式
  - 新增 `isScrolled` 参数，通过 `GeometryReader` 或父视图传入滚动偏移量
- **注意**: 重构后需更新所有使用 `CustomNavBar` 的视图

#### Task 3.8：BottomTabBar（重构现有）
- **文件**: `Components/Navigation/BottomTabBar.swift`
- **关键点**:
  - 新增中间 FAB 浮动按钮
  - 统一激活色为 `appPrimary`
  - 实现激活指示器（Tab图标上方小圆点或小条）的 spring 动画

#### Task 3.9：SearchBar + DateRangePicker
- **文件**: `Components/Input/SearchBar.swift`, `Components/Input/DateRangePicker.swift`
- **关键点**: `DateRangePicker` 使用 `matchedGeometryEffect` 实现滑块动画

---

### Phase 4：ViewModel 层（依赖 Phase 2）

**目标**: 实现所有 ViewModel，将业务逻辑从 View 中剥离。

#### Task 4.1：AppViewModel
- **文件**: `BillManager/ViewModels/AppViewModel.swift`
- **关键点**:
  - 管理全局 `currentLedger` 状态
  - 处理 `UserDefaults` 的账本持久化
  - 通过 `@Environment` 注入到全应用

#### Task 4.2：BillListViewModel
- **文件**: `BillManager/ViewModels/BillListViewModel.swift`
- **关键点**:
  - 月份导航逻辑（`navigateToPreviousMonth` / `navigateToNextMonth`）
  - 搜索过滤（`filteredBills` 计算属性，监听 `searchText`）
  - 月度汇总通过 `StatisticsService.calculateMonthlySummary` 获取

#### Task 4.3：StatisticsViewModel
- **文件**: `BillManager/ViewModels/StatisticsViewModel.swift`
- **关键点**:
  - 时间范围切换时触发 `loadStatistics()`
  - 账本切换时（监听 `AppViewModel.currentLedger`）触发重新加载

#### Task 4.4：AddRecordViewModel
- **文件**: `BillManager/ViewModels/AddRecordViewModel.swift`
- **关键点**:
  - 实时金额输入验证（防止非数字字符）
  - 类型切换时清空分类选择并重新加载对应类型分类
  - 保存成功后设置 `saveSuccess = true`（供 View 展示 Toast）

#### Task 4.5：BillEditorViewModel
- **文件**: `BillManager/ViewModels/BillEditorViewModel.swift`
- **关键点**:
  - 查看模式 / 编辑模式切换
  - 编辑时需回填现有账单数据到各字段

#### Task 4.6：LedgerListViewModel + SettingsViewModel
- **文件**: `BillManager/ViewModels/LedgerListViewModel.swift`, `SettingsViewModel.swift`

---

### Phase 5：视图重构（依赖 Phase 3 + Phase 4）

**目标**: 重构所有 View，使其零业务逻辑，完全通过 ViewModel 驱动。

#### Task 5.1：重构 ContentView + BillManagerApp（依赖注入根节点）
- **文件**: `App/BillManagerApp.swift`, `App/ContentView.swift`
- **关键变更**:
  - `BillManagerApp` 中创建所有 Repository 和 Service 实例，通过 `.environment()` 注入
  - `ContentView` 持有 `@State var appViewModel = AppViewModel(...)`
  - 移除 `ContentView.initializeDefaultLedgerIfNeeded()`，改为调用 `appViewModel.onAppLaunch()`
  - 集成 `BottomTabBar` 替换系统 `TabView`

#### Task 5.2：重构 LedgerListView
- **关键变更**:
  - 移除所有 `@Environment(\.modelContext)` 依赖
  - 移除 `saveLedger`、`archiveLedger`、`deleteLedger` 等 CRUD 方法
  - 移除重复的 `createDefaultCategories()`
  - 改为调用 `LedgerListViewModel` 对应方法
  - 使用 `CardView`、`IconBadge`、`SectionHeader`、`EmptyStateView` 组件

#### Task 5.3：重构 BillListView
- **关键变更**:
  - 移除 `var totalIncome`、`var totalExpense`、`var balance` 计算属性
  - 移除 `saveBill()`、`deleteBill()` 方法
  - 改为绑定 `BillListViewModel`
  - 月度汇总卡片从 `viewModel.monthlySummary` 读取
  - 使用 `SearchBar`、`TagChip`、`AmountDisplay`、`SectionHeader`、`EmptyStateView` 组件
  - 使用 `CustomNavBar` 展示账本名称和切换入口

#### Task 5.4：重构 AddRecordView
- **关键变更**:
  - 移除 `saveBill()` 私有方法
  - 改为调用 `AddRecordViewModel.saveRecord()`
  - 使用 `PrimaryButton`、`IconBadge`、`TagChip` 组件
  - 实现保存成功 Toast（监听 `viewModel.saveSuccess`）

#### Task 5.5：重构 BillEditorView
- **关键变更**:
  - 移除 `@Environment(\.modelContext)` 依赖
  - 改为调用 `BillEditorViewModel`
  - 实现查看/编辑双模式 UI 切换（对应 UI 规范 §7.4）
  - 使用 `AmountDisplay`、`IconBadge`、`CardView`、`PrimaryButton` 组件

#### Task 5.6：重构 StatisticsView
- **关键变更**:
  - 移除所有统计计算逻辑（约 60 行）
  - 图表数据从 `viewModel.dailyStats`、`viewModel.categoryStats` 读取
  - 使用 `DateRangePicker`、`TagChip`、`CardView`、`AmountDisplay`、`SectionHeader` 组件
  - 使用 `LoadingIndicator` 处理加载状态

#### Task 5.7：重构 SettingsView
- **关键变更**:
  - 移除 `exportData()`、`clearAllData()` 方法（移至 SettingsViewModel）
  - 改为调用 `SettingsViewModel` 对应方法
  - 使用 `CardView`、`SectionHeader` 组件统一设置行样式

---

### Phase 6：测试更新（依赖 Phase 5）

**目标**: 确保重构后功能正确性不退化，增加关键路径单元测试。

#### Task 6.1：Repository 层测试
- **文件**: `BillManagerTests/Repositories/`
- **测试内容**:
  - `BillRepositoryTests`: CRUD 操作、时间范围过滤、搜索功能
  - `LedgerRepositoryTests`: 创建/归档/恢复/删除、级联删除账单验证
  - `CategoryRepositoryTests`: 默认分类创建、按类型查询
- **测试环境**: 使用 `inMemory: true` 的 `ModelContainer`

#### Task 6.2：Service 层测试
- **文件**: `BillManagerTests/Services/`
- **测试内容**:
  - `StatisticsServiceTests`: 统计算法正确性（分类占比计算、日趋势生成）
  - `BillServiceTests`: 金额验证、账单创建完整性
  - `LedgerServiceTests`: 默认账本初始化逻辑

#### Task 6.3：ViewModel 层测试
- **文件**: `BillManagerTests/ViewModels/`
- **测试内容**:
  - `BillListViewModelTests`: 月份导航、搜索过滤
  - `AddRecordViewModelTests`: 输入验证、保存流程
  - `StatisticsViewModelTests`: 时间范围切换后数据更新

---

## 7. 重构风险与注意事项

### 7.1 数据迁移策略

**背景**: 当前 `Bill.amount` 为 `Double` 类型，建议迁移为 `Decimal` 以避免浮点精度问题。

**方案 A（推荐）: 渐进式迁移**
```
短期（当前版本）:
  - 保持 Bill.amount 为 Double
  - 在 Repository 层封装 Double↔Decimal 转换
  - Extensions.swift 中 currencyFormatted 基于 Decimal 实现

中期（下一版本）:
  - 使用 SwiftData Migration 机制
  - 新增 SchemaMigrationPlan，将 amount: Double 迁移为 amount: Decimal
  - 在 BillManagerApp 中配置 migrationPlan
```

**方案 B: 跳过，保持 Double**
- 若团队时间有限，可保持 `Double`，在 ViewModel 层统一格式化即可
- 务必使用 `Decimal(string:)` 解析用户输入，避免 `Double(string:)` 的精度损失

**SwiftData 迁移代码示例（若执行方案A）**:
```swift
enum BillMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] = [
        BillSchemaV1.self,
        BillSchemaV2.self,
    ]
    static var stages: [MigrationStage] = [
        migrateV1toV2
    ]
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: BillSchemaV1.self,
        toVersion: BillSchemaV2.self,
        willMigrate: nil,
        didMigrate: { context in
            // 在此做 Double → Decimal 的数据转换
        }
    )
}
```

### 7.2 SwiftData 兼容性注意点

1. **FetchDescriptor Predicate 限制**
   - SwiftData 的 `#Predicate` 宏对字符串 `contains` 支持有限，搜索功能建议在内存中过滤
   - `bill.ledger?.id == ledgerId` 跨关系查询需谨慎测试
   - 复杂 OR 条件在 SwiftData Predicate 中语法较繁琐

2. **@Model 类线程安全**
   - `@Model` 实例绑定到特定 `ModelContext` 所在的 Actor
   - `BillRepository` 中的操作应在 `@MainActor` 上执行（或使用 `ModelActor`）
   - 若未来需要后台处理，需引入 `ModelActor`

3. **懒加载关系（Lazy Loading）**
   - `Ledger.bills` 和 `Ledger.categories` 是懒加载的
   - 在 `Repository.fetchBills` 中不要依赖 `ledger.bills?.filter`，应使用 `FetchDescriptor` 独立查询
   - `Ledger.totalIncome` 等计算属性依赖懒加载，在 Repository 外使用时需确保已访问过该关系

4. **SwiftData 在 Preview 中的配置**
   - 所有 View 的 Preview 需配置 `inMemory: true` 的 ModelContainer
   - ViewModel 的 Preview 需使用 Mock Service（推荐为每个 Protocol 创建 MockXxxService 实现）

### 7.3 渐进式重构建议

**强烈建议不要一次性重构所有文件**，推荐以下渐进策略：

```
第1周: Phase 0 + Phase 1（基础设施 + Repository）
  → 此阶段现有功能不受影响，Repository 只是新增层

第2周: Phase 2 + Phase 3 前半（Service + 基础组件）
  → Service 层开发完成，但暂时未被 View 使用
  → 组件开发，可在独立 Preview 中验证

第3周: Phase 3 后半 + Phase 4（剩余组件 + ViewModel）
  → ViewModel 开发完成，但暂时未被 View 使用

第4周: Phase 5（视图重构）
  → 一次性切换，用 Git Feature Branch
  → 每完成一个 View 重构，立即测试验证

第5周: Phase 6 + 回归测试
```

**每个 Phase 的分支策略**:
```
main
  └── feature/architecture-phase0    # 基础设施
        └── feature/architecture-phase1  # Repository
              └── feature/architecture-phase2  # Service
                    └── ...
```

### 7.4 错误处理统一规范

重构后所有错误必须统一走 `AppError` 流，View 层统一处理方式：

```swift
// View 中统一的错误展示
.alert("操作失败", isPresented: .init(
    get: { viewModel.error != nil },
    set: { if !$0 { viewModel.error = nil } }
)) {
    Button("好的") { viewModel.error = nil }
} message: {
    Text(viewModel.error?.localizedDescription ?? "未知错误")
}
```

对于非阻断性错误（如网络请求失败），使用 Toast 展示而非 Alert。

### 7.5 性能注意事项

1. **统计计算性能**: `StatisticsService.calculateDailyTrend` 在年度视图下需遍历365天，若账单量大，需考虑异步执行（`async throws`）并在 ViewModel 中配合 `isLoading` 状态显示加载指示器

2. **列表渲染性能**: `BillListView` 使用 `LazyVStack` 而非 `List` 时，需确保 `BillRow` 没有不必要的重计算；使用 `id` 参数优化重渲染

3. **SwiftData 查询效率**: 避免在 Repository 中使用 `fetchAll` 后再内存过滤；优先使用 `FetchDescriptor` 的 `predicate` 让数据库层面过滤

---

## 附录：接口速查表

| 层级 | 文件 | 核心方法 |
|------|------|---------|
| Repository | BillRepository | fetchBills / createBill / updateBill / deleteBill |
| Repository | LedgerRepository | fetchActiveLedgers / createLedger / archiveLedger / deleteLedger |
| Repository | CategoryRepository | fetchCategories / createDefaultCategories |
| Service | BillService | addBill / updateBill / deleteBill / fetchBills |
| Service | LedgerService | createLedger / initializeDefaultLedgerIfNeeded / resolveCurrentLedger |
| Service | StatisticsService | calculateStatistics / calculateMonthlySummary / calculateCategoryStats |
| ViewModel | AppViewModel | selectLedger / onAppLaunch |
| ViewModel | BillListViewModel | loadBills / navigateToPreviousMonth / navigateToNextMonth / deleteBill |
| ViewModel | StatisticsViewModel | loadStatistics / selectTimeRange / selectBillType |
| ViewModel | AddRecordViewModel | loadCategories / saveRecord / reset |
| ViewModel | BillEditorViewModel | enterEditMode / saveChanges / deleteBill |
| ViewModel | LedgerListViewModel | loadLedgers / createLedger / archiveLedger / confirmDelete |
| ViewModel | SettingsViewModel | exportData / clearAllData |

---

*文档版本: v1.0 | 最后更新: 2026-04-03 | 作者: 系统架构师（同事二）*
