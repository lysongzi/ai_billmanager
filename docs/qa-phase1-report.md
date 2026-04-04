# QA Phase 1 报告：现有代码质量分析与测试策略制定

**报告日期**: 2026-04-03
**报告人**: QA 工程师（同事四）
**评估对象**: BillManager iOS 应用 — 重构前现有代码
**代码版本**: main 分支，最新提交 `c63f02a`

---

## 1. 执行摘要

### 整体质量评分：5.5 / 10

| 维度 | 评分 | 说明 |
|------|------|------|
| 架构设计 | 4/10 | MVC/MVVM 混乱，视图承载了大量业务逻辑 |
| 代码规范 | 6/10 | 命名基本规范，但缺乏注释，存在硬编码 |
| 测试覆盖 | 6/10 | 有基础测试但覆盖不完整，缺少视图与数据层测试 |
| 潜在Bug | 4/10 | 存在多处逻辑错误与边界处理缺失 |
| 性能隐患 | 5/10 | 视图内存在冗余计算，大列表无优化 |

### 关键发现

1. **架构问题突出**：所有业务逻辑（CRUD、统计计算、数据初始化）直接写在 View 层，没有 ViewModel / Service / Repository 分层，导致代码难以测试和复用。
2. **存在真实 Bug**：`TimeRange.year.dateRange()` 计算年末日期使用 `DateComponents(month: 11, day: 31)` 存在逻辑错误，会产生错误的年度统计范围。
3. **代码严重重复**：`createDefaultCategories()` 函数在 `ContentView` 和 `LedgerListView` 中完全重复定义。
4. **危险操作无防护**：`clearAllData()` 删除所有账本和账单，没有二次确认弹窗，直接执行不可恢复的操作。
5. **设计系统使用不一致**：`DesignSystem.swift` 定义了 `AppColors`，但在多个视图中（`StatisticsView`、`LedgerListView`）大量使用内联 `Color(red:green:blue:)` 硬编码，违反设计规范。
6. **保存错误被静默忽略**：所有 `try? modelContext.save()` 均不处理错误，数据库写入失败对用户完全透明。

---

## 2. 现有代码质量问题清单（按严重程度排序）

### 严重（Critical）

#### C-01：清空数据无二次确认
**文件**: `SettingsView.swift` — `clearAllData()` 函数
**问题**: `clearAllData()` 删除所有账本和账单，UI 按钮 `Button(role: .destructive)` 点击即触发，没有系统级 `alert` 确认。与 `deleteLedger` 有确认流程相比，存在严重不一致。
**风险**: 用户误触导致不可恢复的数据丢失。

#### C-02：TimeRange.year 日期计算错误
**文件**: `Statistics.swift` — `TimeRange.dateRange()` 函数（第 111 行）
**问题**:
```swift
// 错误实现：month: 11, day: 31 并不等于 12 月 31 日
let end = calendar.date(byAdding: DateComponents(month: 11, day: 31), to: start)!
```
从 1 月 1 日加 11 个月得到 12 月 1 日，再加 31 天得到 2 月 1 日（跨年），而非 12 月 31 日。
**风险**: 年度统计数据包含下一年度 1 月的数据，统计结果不准确。

#### C-03：saveBill 的 force-unwrap 风险
**文件**: `StatisticsView.swift` — `categoryStats` 计算属性（第 43 行）
**问题**:
```swift
let firstBill = bills.first!  // 强制解包
```
`grouped.map` 中对 `bills.first!` 使用强制解包。理论上 `Dictionary(grouping:)` 保证每组至少有一个元素，但代码风格不安全，维护者容易引入类似错误。

---

### 高（High）

#### H-01：业务逻辑与视图强耦合
**文件**: 所有 View 文件
**问题**: CRUD 操作、数据计算、统计逻辑均直接写在 View 的 `private func` 中，以下函数不应存在于 View 层：
- `BillListView.saveBill()` / `deleteBill()`
- `LedgerListView.saveLedger()` / `archiveLedger()` / `restoreLedger()` / `deleteLedger()`
- `StatisticsView.categoryStats` / `dailyStats`（复杂计算属性）
- `ContentView.initializeDefaultLedgerIfNeeded()` / `createDefaultCategories()`
- `SettingsView.exportData()` / `clearAllData()`

**风险**: View 无法进行单元测试，业务逻辑无法复用。

#### H-02：createDefaultCategories() 代码完全重复
**文件**: `ContentView.swift`（第 48-80 行）、`LedgerListView.swift`（第 148-178 行）
**问题**: 两处完全相同的函数，12个分类数据完全一致，违反 DRY 原则。未来修改需同步维护两处。

#### H-03：所有 SwiftData 错误被静默忽略
**文件**: 所有 View 文件
**问题**: 全部使用 `try? modelContext.save()`，错误被丢弃，无日志、无 UI 反馈。
**影响文件**:
- `BillListView.swift` — `saveBill()`, `deleteBill()`
- `LedgerListView.swift` — `saveLedger()`, `archiveLedger()`, `deleteLedger()`
- `ContentView.swift` — `initializeDefaultLedgerIfNeeded()`
- `SettingsView.swift` — `clearAllData()`

#### H-04：BillEditorView 与 QuickAddView 大量重复
**文件**: `BillEditorView.swift`（第 167-322 行 `QuickAddView`）
**问题**: `QuickAddView` 与 `BillEditorView` 的核心逻辑高度重合（分类过滤、金额验证、账单保存），仅 UI 布局有差异，但被实现为两个独立组件，逻辑未共享。

#### H-05：AddRecordView 与 BillEditorView 功能重叠
**文件**: `AddRecordView.swift`
**问题**: `AddRecordView` 是另一个添加账单的视图，与 `BillEditorView` 功能重叠。两者共存但职责不清，增加维护难度，也说明重构前已经有重构行为但未完成。

---

### 中等（Medium）

#### M-01：硬编码颜色值大量存在
**文件**: `StatisticsView.swift`、`LedgerListView.swift`、`SettingsView.swift`
**问题**: 已定义 `DesignSystem.swift`（`AppColors`），但多处仍使用 `Color(red: 28/255, green: 25/255, blue: 23/255)` 等内联硬编码，与设计系统脱节。粗略统计超过 30 处。

#### M-02：StatisticsView 统计计算在 View 中执行，无缓存
**文件**: `StatisticsView.swift` — `filteredBills`, `categoryStats`, `dailyStats`
**问题**: 三个计算属性均为 `private var`，每次 View 刷新时重复遍历账单数据。当账单数量较大时（数百条+），每次 SwiftUI 视图更新都会触发全量数组遍历，存在性能隐患。

#### M-03：LedgerListView 查询所有账单但未使用
**文件**: `LedgerListView.swift`（第 7 行）
**问题**:
```swift
@Query private var allBills: [Bill]  // 查询了所有账单但在视图中未见明确使用
```
无用的全量查询，影响性能，且造成代码阅读困惑。

#### M-04：StatisticsView 有死代码（trendChartSection）
**文件**: `StatisticsView.swift`（第 319-359 行）
**问题**: `trendChartSection` 已定义完整的趋势图组件，但在 `body` 中从未调用，属于无效代码。

#### M-05：日期范围比较未使用 startOfDay/endOfDay
**文件**: `StatisticsView.swift`（第 28-31 行）、`Extensions.swift`（第 119-127 行）
**问题**: 时间范围过滤使用 `bill.date >= startDate && bill.date <= endDate`，但 `startDate` 是当天的 `startOfDay`，`endDate` 是当天的某个时间点（而非 `endOfDay`），导致当天最后几秒的账单可能被错误过滤（对 `.week` 和 `.month` 的 end 日期来说是精确到日的开始时间，非结束时间）。

#### M-06：UserDefaults key "lastSelectedLedgerId" 硬编码字符串分散各处
**文件**: `ContentView.swift`、`StatisticsView.swift`、`SettingsView.swift`
**问题**: 相同的 UserDefaults key `"lastSelectedLedgerId"` 出现在三个文件中，没有集中常量定义，字符串拼写错误风险高。

#### M-07：BillEditorView 保存逻辑在父视图（职责不清）
**文件**: `BillListView.swift` — `saveBill(_:)`
**问题**: `BillEditorView` 通过 `onSave` 回调将 Bill 对象传回给父视图 `BillListView` 处理保存，但 `BillEditorView` 的 `saveBill()` 内部又创建了新的 Bill 对象，存在数据流向混乱（创建 Bill 在 Editor，持久化在 ListView）。

---

### 低（Low）

#### L-01：注释覆盖率极低
**问题**: 整个代码库几乎没有任何文档注释（`///`）或行内注释，没有任何函数级别的说明，仅有少量结构性注释。

#### L-02：BillListView 统计数据与 Ledger 模型的计算重复
**文件**: `BillListView.swift`（第 180-190 行）、`Ledger.swift`（第 37-47 行）
**问题**: `BillListView` 重新计算 `totalIncome`、`totalExpense`、`balance`，而 `Ledger` 模型上已有同名计算属性。前者基于过滤后的 `bills`（含搜索），后者基于全量，逻辑稍有不同，但命名完全相同，容易混淆。

#### L-03：selectedLedger 在 LedgerListView 未使用
**文件**: `LedgerListView.swift`（第 9 行）
**问题**: `@State private var selectedLedger: Ledger?` 声明后，在视图体内均通过 `NavigationLink` 和 `editingLedger` 操作，`selectedLedger` 未被任何地方赋值和使用，是废弃状态变量。

#### L-04：导出功能使用 UIKit 接口，非 SwiftUI 方式
**文件**: `SettingsView.swift` — `exportData()` 函数
**问题**: 直接使用 `UIActivityViewController` 和 `UIApplication.shared.connectedScenes`，在 SwiftUI 中应使用 `ShareLink` 组件，当前实现为平台耦合代码。

#### L-05：版本号硬编码在两处 View
**文件**: `SettingsView.swift`（第 270 行）、`AboutView`（第 366 行）
**问题**: "1.0.0" 字符串硬编码，应从 Bundle 动态读取。

---

## 3. 现有测试覆盖率分析

### 3.1 测试文件概况

| 测试文件 | 测试用例数 | 主要覆盖范围 |
|---------|----------|------------|
| `ModelTests.swift` | 10 | Ledger、Bill、Category 模型初始化与基础属性 |
| `StatisticsTests.swift` | 9 | TimeRange 日期范围、BillType 枚举、统计结构体初始化 |
| `ExtensionTests.swift` | 16 | Date 扩展、Double.currencyFormatted、Color(hex:)、Array+Bill 扩展 |
| **合计** | **35** | |

### 3.2 已覆盖功能

- Ledger 模型初始化、默认值、totalIncome/totalExpense/balance 计算
- Bill 模型初始化、类型转换（typeRawValue ↔ BillType）、note 可选值
- Category 模型初始化和类型转换
- TimeRange 的 dateRange() 基础正确性（week/month/year）
- TimeRange、BillType 的显示名称和图标
- CategoryStat、DailyStat、Statistics 结构体初始化
- Date 扩展：startOfDay、endOfDay、isToday、isYesterday、relativeDescription、formatted(as:) 等
- Double.currencyFormatted 格式化
- Color(hex:) 初始化（含 3 位、6 位、非法值）
- Array+Bill 扩展：groupedByDate()、filtered(by:)、totalIncome/totalExpense

### 3.3 未覆盖功能（测试盲区）

| 功能模块 | 未覆盖原因 | 风险等级 |
|---------|----------|---------|
| **TimeRange.year 年末日期计算** | 已知 Bug，现有测试只验证 start <= end，未验证具体日期值 | 高 |
| **账单 CRUD 操作（持久化层）** | 没有 SwiftData 集成测试 | 高 |
| **默认分类创建逻辑** | 无测试，重复代码也无测试 | 中 |
| **导出 CSV 生成逻辑** | `exportData()` 完全无测试 | 中 |
| **视图状态管理** | 所有 View 无任何测试 | 中 |
| **searchText 过滤逻辑** | `BillListView.bills` 计算属性无测试 | 中 |
| **金额输入验证（isValid）** | 两处 isValid 计算属性无测试 | 中 |
| **lastSelectedLedgerId 持久化** | UserDefaults 读写逻辑无测试 | 低 |
| **Color(hex:) 边界值** | 只测试了存在性（notNil），未验证颜色分量值 | 低 |
| **categoryStats 百分比计算** | 核心统计逻辑无专项测试 | 高 |
| **filteredBills 日期边界** | 跨天/跨月边界场景无测试 | 中 |
| **DailyStat.amount** | `amount = income + expense`，但语义上 amount 应是总金额，未验证业务语义是否正确 | 低 |
| **Ledger.balance 空账单** | bills 为 nil 时的保护逻辑有测试但未覆盖 bills 为空数组情况 | 低 |

### 3.4 测试质量评估

**优点**:
- 模型层基础测试完整，覆盖了初始化和默认值
- Extension 测试覆盖了多种日期场景
- 使用 `@testable import` 正确

**缺点**:
- 测试均为"正向路径"测试，缺乏边界条件和错误路径
- 测试未验证关键业务逻辑（分类统计计算、百分比计算）
- `testTimeRangeYear()` 只验证 `start <= end` 和 month=1，未能捕获已知 Bug
- `testColorHexInit()` 只验证 `XCTAssertNotNil`，没有验证颜色值正确性
- 缺乏 `tearDown` 清理，虽然当前测试不依赖持久化状态，重构后需要
- 无 Performance 测试

---

## 4. 潜在 Bug 清单

| ID | 文件 | 位置 | 描述 | 严重程度 |
|----|------|------|------|---------|
| BUG-01 | `Statistics.swift` | line 111 | `TimeRange.year` 年末日期计算错误：`DateComponents(month: 11, day: 31)` 在 1 月 1 日基础上加 11 个月再加 31 天，实际结果是下一年 2 月，而非本年 12 月 31 日 | Critical |
| BUG-02 | `SettingsView.swift` | `clearAllData()` | 清空所有数据无二次确认弹窗，误触导致全部数据丢失 | Critical |
| BUG-03 | `StatisticsView.swift` | line 43 | `let firstBill = bills.first!` 强制解包，理论安全但风格危险 | High |
| BUG-04 | `Statistics.swift` | `TimeRange.dateRange()` | `.week` 的 end 日期是 `start + 6天` 的起始时间（00:00:00），不包含最后一天的所有账单（23:59:59 之前的账单丢失） | High |
| BUG-05 | `Statistics.swift` | `TimeRange.dateRange()` | `.month` 的 end 日期是月末当天 00:00:00，非 23:59:59，月末当天账单无法被统计 | High |
| BUG-06 | `BillEditorView.swift` | `saveBill()` | 编辑账单时创建新 Bill 对象后通过 `onSave` 回调，父视图 `BillListView.saveBill()` 更新字段；但创建的新 Bill 和旧 Bill 均注入了相同的 id，两个 Bill 对象均存在于内存中直到 dismiss，可能造成短暂数据不一致 | Medium |
| BUG-07 | `ContentView.swift` | `initializeDefaultLedgerIfNeeded()` | 仅检查 `ledgers.isEmpty`，如果账本被全部删除后重新打开 App，会重新创建默认账本，但 UserDefaults 中残留的旧 ledgerId 可能导致 StatisticsView 无法匹配账本 | Medium |
| BUG-08 | `BillEditorView.swift` | `onAppear` | 编辑已有账单时，通过 `categories.first { $0.name == bill.categoryName }` 恢复分类选中状态；如果分类被删除或重命名，会导致 `selectedCategory` 为 nil，用户无法直接保存 | Medium |
| BUG-09 | `BillListView.swift` | line 192-196 | `dailyTotal(for:)` 返回 `income - expense`（净额），在列表 header 显示为"当日总额"，但语义上不明确是"净额"还是"支出总额"，可能误导用户 | Low |
| BUG-10 | `Extensions.swift` | line 99 | `startOfWeek` 假设周从周一开始（weekday: 2），但在美国等地区系统 Calendar 默认周日为第一天，会造成错误的周统计范围 | Low |

---

## 5. 性能隐患清单

| ID | 文件 | 描述 | 潜在影响 |
|----|------|------|---------|
| PERF-01 | `StatisticsView.swift` | `categoryStats` 和 `dailyStats` 是计算属性，每次视图重新渲染都全量遍历账单，无缓存机制 | 账单数量大时 UI 卡顿 |
| PERF-02 | `BillListView.swift` | `bills`（含过滤和排序）、`groupedBills`、`totalIncome`、`totalExpense`、`balance` 均为无缓存的计算属性，会在每次 View 刷新时重复计算 | 列表滚动时可能卡顿 |
| PERF-03 | `LedgerListView.swift` | `@Query private var allBills: [Bill]` 加载全量账单，但在视图中未使用，造成无效的数据库查询和内存占用 | 数据量大时启动缓慢 |
| PERF-04 | `StatisticsView.swift` `dailyStats` | 按天遍历日期范围内每天，再对每天做账单过滤（`Calendar.current.isDate` 逐条判断），时间复杂度 O(days × bills)，对全年视图（365天 × 大量账单）性能极差 | 年度视图切换缓慢 |
| PERF-05 | `Extensions.swift` `relativeDescription` | 每次调用创建新的 `DateFormatter` 实例（3 个分支各创建一次），DateFormatter 实例化开销较大，在列表高频调用时影响滚动性能 | 列表滚动掉帧 |
| PERF-06 | `Extensions.swift` `currencyFormatted` | 每次调用创建新的 `NumberFormatter` 实例，列表中每个账单行都创建一次，缓存缺失 | 列表渲染慢 |
| PERF-07 | `BillListView.swift` | 使用 `.insetGrouped` 列表样式，对于大量账单未启用 `LazyVStack` 或分页加载，全量渲染 | 数百条账单时 UI 卡顿 |
| PERF-08 | `StatisticsView.swift` | `filteredBills` 每次都基于 `currentLedger` 的 `bills` 全量过滤，SwiftData 的 `@Query` 应在查询层面进行过滤（`#Predicate`）而非内存过滤 | 无法利用 SwiftData 查询优化 |

---

## 6. 重构后测试策略（详细）

### 6.1 测试架构总览

重构后应按照以下分层进行测试：

```
Unit Tests
├── Repository Tests     (数据持久化层：SwiftData CRUD)
├── Service Tests        (业务逻辑层：统计计算、验证)
├── ViewModel Tests      (状态管理层：UI 状态变更)
└── Utility Tests        (工具层：Extension、DesignSystem)

Integration Tests
├── Data Flow Tests      (View → ViewModel → Service → Repository → SwiftData)
└── User Journey Tests   (关键用户流程端到端)

UI Tests (可选)
└── Snapshot Tests       (关键界面截图对比)
```

---

### 6.2 Repository 层测试策略

Repository 负责与 SwiftData 交互，需使用 **in-memory 数据库** 进行隔离测试。

**测试要点**：

**LedgerRepository 测试**：
```
- testCreateLedger_shouldPersistCorrectly()
- testCreateLedger_withDefaultValues_shouldUseDefaults()
- testFetchAllLedgers_shouldReturnSortedByCreatedAtDesc()
- testFetchLedger_byId_shouldReturnCorrectLedger()
- testFetchLedger_withNonExistentId_shouldReturnNil()
- testUpdateLedger_shouldModifyCorrectFields()
- testDeleteLedger_shouldCascadeDeleteBillsAndCategories()
- testArchiveLedger_shouldChangeIsArchivedFlag()
- testFetchArchivedLedgers_shouldOnlyReturnArchived()
- testCreateLedger_withEmptyName_shouldFail()（边界）
- testCreateLedger_concurrentInserts_shouldNotConflict()（并发边界）
```

**BillRepository 测试**：
```
- testCreateBill_shouldPersistCorrectly()
- testCreateBill_withNullNote_shouldStoreNil()
- testFetchBills_forLedger_shouldReturnOnlyThatLedgerBills()
- testFetchBills_withDateFilter_shouldRespectDateRange()
- testFetchBills_withTypeFilter_shouldFilterCorrectly()
- testFetchBills_withSearchText_shouldMatchCategoryNameAndNote()
- testUpdateBill_shouldUpdateAllFields_andUpdateTimestamp()
- testDeleteBill_shouldRemoveFromLedger()
- testDeleteBill_nonExistent_shouldNotCrash()
- testCreateBill_withZeroAmount_shouldFail()（边界）
- testCreateBill_withNegativeAmount_shouldFail()（边界）
- testCreateBill_withFutureDateLimit()（边界）
```

**CategoryRepository 测试**：
```
- testCreateDefaultCategories_shouldCreate12Categories()
- testCreateDefaultCategories_shouldHave8Expense4Income()
- testFetchCategories_byLedger_shouldReturnOnlyLinkedCategories()
- testFetchCategories_byType_shouldFilterCorrectly()
- testDeleteCategory_shouldNotCascadeDeleteBills()（联级保护验证）
```

---

### 6.3 Service 层测试策略

Service 层包含纯业务逻辑，应为纯 Swift 函数，**不依赖 SwiftData**，使用 Mock 数据测试。

**StatisticsService 测试**：
```
- testCalculateTotalIncome_withMixedBills_shouldSumCorrectly()
- testCalculateTotalExpense_withMixedBills_shouldSumCorrectly()
- testCalculateBalance_positive_shouldBePositive()
- testCalculateBalance_negative_shouldBeNegative()
- testCalculateBalance_zero_shouldBeZero()
- testCategoryBreakdown_shouldGroupByCategory()
- testCategoryBreakdown_percentageSum_shouldApproximately100()
- testCategoryBreakdown_emptyBills_shouldReturnEmpty()
- testDailyStats_shouldGenerateContinuousDates()
- testDailyStats_noGapInDateRange()
- testDailyStats_dailyTotalShouldMatchBillsForThatDay()
- testFilterByTimeRange_week_shouldOnlyIncludeCurrentWeekBills()
- testFilterByTimeRange_month_shouldIncludeAllDaysOfMonth()（含月末边界）
- testFilterByTimeRange_year_shouldIncludeAllDaysOfYear()（含 12 月 31 日）
- testFilterByTimeRange_year_shouldNotIncludeNextYearBills()（跨年边界）
```

**BillService / LedgerService 测试**：
```
- testValidateAmount_positive_shouldBeValid()
- testValidateAmount_zero_shouldBeInvalid()
- testValidateAmount_negative_shouldBeInvalid()
- testValidateAmount_nonNumericString_shouldBeInvalid()
- testValidateAmount_extremelyLarge_shouldBeHandled()
- testExportCSV_shouldIncludeAllBills_inCorrectFormat()
- testExportCSV_noteWithComma_shouldEscapeCorrectly()
- testExportCSV_emptyBills_shouldReturnHeaderOnly()
- testCreateDefaultCategories_shouldNotDuplicate()
```

---

### 6.4 ViewModel 测试策略

ViewModel 负责 View 状态，需 Mock Service/Repository 层，使用 `@MainActor` 测试。

**LedgerListViewModel 测试**：
```
- testLoadLedgers_shouldFetchAndUpdateState()
- testAddLedger_shouldCreateWithDefaultCategories()
- testAddLedger_withEmptyName_shouldNotProceed()
- testEditLedger_shouldUpdateExistingFields()
- testArchiveLedger_shouldMoveToArchived()
- testRestoreLedger_shouldMoveToActive()
- testDeleteLedger_shouldShowConfirmationFirst()
- testDeleteLedger_confirmedWithBills_shouldCascade()
- testSearchText_filtering_shouldReactToChange()
```

**BillListViewModel 测试**：
```
- testLoadBills_forLedger_shouldPopulateState()
- testFilterBills_bySearchText_shouldFilterCategoryName()
- testFilterBills_bySearchText_shouldFilterNote()
- testFilterBills_clearSearch_shouldShowAll()
- testSaveBill_new_shouldAddToLedger()
- testSaveBill_editing_shouldUpdateExistingBill()
- testSaveBill_editing_shouldUpdateTimestamp()
- testDeleteBill_shouldRemoveFromList()
- testGroupedBills_shouldGroupByDayDescending()
- testSummary_shouldRecalculateAfterSave()
```

**StatisticsViewModel 测试**：
```
- testSelectLedger_shouldPersistToUserDefaults()
- testSwitchTimeRange_shouldRecalculateStats()
- testSwitchBillType_shouldUpdateCategoryStats()
- testCategoryStats_empty_shouldShowEmptyState()
- testCurrentLedger_restoredFromUserDefaults_afterRestart()
```

---

### 6.5 Extension / Utility 测试（补充现有测试）

**补充测试用例（现有测试的增强）**：

```
TimeRange 测试（修复现有不完整测试）：
- testTimeRangeYear_endDate_shouldBeDecember31st()  // 修复 BUG-01
- testTimeRangeWeek_endDate_shouldIncludeEndOfLastDay()  // 修复 BUG-04
- testTimeRangeMonth_endDate_shouldIncludeEndOfLastDay()  // 修复 BUG-05
- testTimeRangeCustom_shouldReturnCurrentDate()

Color(hex:) 测试（修复现有不精确测试）：
- testColorHexInit_6digit_shouldParseRGBCorrectly()  // 验证颜色分量值
- testColorHexInit_3digit_shouldExpandCorrectly()
- testColorHexInit_withHashPrefix_shouldHandleCorrectly()
- testColorHexInit_uppercase_shouldWork()
- testColorHexInit_emptyString_shouldReturnBlack()

NumberFormatter 性能测试：
- testCurrencyFormatted_performance_largeVolume()  // 验证 PERF-06

DateFormatter 缓存测试：
- testRelativeDescription_performance_largeVolume()  // 验证 PERF-05
```

---

### 6.6 集成测试策略

**数据流集成测试**（使用 in-memory SwiftData）：

```
- testBillCreationFlow_endToEnd_shouldPersistAndReflectInStatistics()
  // 创建账单 → 验证 Repository 持久化 → 验证 StatisticsService 统计更新

- testLedgerDeletion_cascadeFlow_shouldDeleteAllAssociatedData()
  // 创建账本+分类+账单 → 删除账本 → 验证所有相关数据删除

- testDefaultLedgerInit_firstLaunch_shouldCreateCorrectStructure()
  // 模拟首次启动 → 验证默认账本和分类创建

- testSearchAndFilter_combinedFlow()
  // 插入多条账单 → 搜索过滤 → 时间范围过滤 → 验证结果一致性

- testStatisticsUpdate_afterBillModification()
  // 修改账单金额或分类 → 验证统计数据实时更新
```

**关键用户流程测试（端到端）**：
```
- 用户流程1：新建账本 → 添加收入账单 → 添加支出账单 → 查看统计 → 确认数据正确
- 用户流程2：编辑已有账单 → 修改金额和分类 → 验证统计变化
- 用户流程3：归档账本 → 验证统计视图不再显示归档账本数据
- 用户流程4：导出账单 CSV → 验证文件内容格式正确
- 用户流程5：快速记账（QuickAdd）→ 验证账单创建并添加到正确账本
```

---

### 6.7 UI 组件测试策略

**CustomNavBar 测试**：
- 有 title 时正确显示
- leftContent 和 rightContent 为空时不崩溃
- rightContent 渲染 NavBarButton 时位置正确
- title 过长时是否省略（截断规则）

**BottomNavBar 测试**：
- 默认选中第一个 tab
- 点击 tab 更新 selectedTab binding
- 激活状态颜色变化正确（tabColors 映射）
- 3 个 tab 均正确渲染 icon 和 label

**CategoryButton（BillEditorView 中）测试**：
- selected 状态边框正确显示
- unselected 状态无边框
- 点击触发 action 回调

**LedgerCardView 测试**：
- 正确显示 totalIncome、totalExpense、balance
- balance >= 0 时使用深色，< 0 时使用红色
- 账单数量正确显示

---

### 6.8 测试数据策略

**Mock 数据设计原则**：
- 所有测试使用确定性的固定日期（避免依赖 `Date()`），除非测试"相对时间"功能
- 使用工厂函数（Factory Functions）统一创建测试用 Model 对象
- 测试账本/账单数量：基础测试3-5条，性能测试100+条

**测试夹具（Fixtures）设计**：

```swift
// TestFixtures.swift
enum TestFixtures {
    // 固定日期
    static let fixedDate = ISO8601DateFormatter().date(from: "2026-01-15T10:00:00Z")!
    static let january1 = ISO8601DateFormatter().date(from: "2026-01-01T00:00:00Z")!
    static let december31 = ISO8601DateFormatter().date(from: "2026-12-31T23:59:59Z")!

    // 标准账本
    static func defaultLedger() -> Ledger {
        Ledger(name: "测试账本", icon: "book.fill", colorHex: "#007AFF")
    }

    // 支出账单
    static func expenseBill(amount: Double = 100.0,
                            category: String = "餐饮",
                            date: Date = fixedDate) -> Bill {
        Bill(amount: amount, type: .expense, categoryName: category,
             categoryIcon: "fork.knife", categoryColorHex: "#FF6B6B",
             date: date)
    }

    // 收入账单
    static func incomeBill(amount: Double = 5000.0,
                           category: String = "工资",
                           date: Date = fixedDate) -> Bill {
        Bill(amount: amount, type: .income, categoryName: category,
             categoryIcon: "banknote.fill", categoryColorHex: "#2ECC71",
             date: date)
    }

    // 跨月分布账单集合
    static func multiMonthBills() -> [Bill] { ... }

    // 年度账单集合（含 12 月 31 日）
    static func fullYearBills() -> [Bill] { ... }
}
```

**Mock 接口设计**（为 Service/Repository 层提供）：
```swift
protocol BillRepositoryProtocol {
    func fetch(for ledger: Ledger) -> [Bill]
    func create(_ bill: Bill, in ledger: Ledger) throws
    func update(_ bill: Bill) throws
    func delete(_ bill: Bill) throws
}

class MockBillRepository: BillRepositoryProtocol {
    var bills: [Bill] = []
    var createCalled = false
    var deletedBills: [Bill] = []
    // 测试用状态追踪...
}
```

---

## 7. 关键测试用例设计（核心场景伪代码）

### TC-001：年度统计 Bug 验证（BUG-01 修复验证）

```swift
func testTimeRangeYear_endDate_shouldBeDecember31st() {
    // Arrange: 固定在 2026 年测试
    let (start, end) = TimeRange.year.dateRange()
    let calendar = Calendar.current

    // Assert: start 必须是 1 月 1 日
    XCTAssertEqual(calendar.component(.month, from: start), 1)
    XCTAssertEqual(calendar.component(.day, from: start), 1)

    // Assert: end 必须是 12 月 31 日（或 23:59:59）
    XCTAssertEqual(calendar.component(.month, from: end), 12)
    XCTAssertEqual(calendar.component(.day, from: end), 31)

    // Assert: start 和 end 在同一年
    XCTAssertEqual(calendar.component(.year, from: start),
                   calendar.component(.year, from: end))
}
```

### TC-002：月末账单不丢失验证（BUG-05 修复验证）

```swift
func testFilterByTimeRange_month_shouldIncludeLastDayBills() {
    // Arrange: 创建月末 23:59 的账单
    let lastDayAt2359 = /* 当月最后一天 23:59:59 */
    let bill = Bill(amount: 100, type: .expense,
                    categoryName: "餐饮", date: lastDayAt2359)

    // Act: 使用当月过滤
    let filtered = [bill].filtered(by: .month)

    // Assert: 月末账单必须被包含
    XCTAssertEqual(filtered.count, 1, "月末账单不应被过滤")
}
```

### TC-003：账单 CRUD 集成测试

```swift
func testBillCRUD_integrationTest() async throws {
    // Arrange: 使用 in-memory container
    let container = try ModelContainer(for: Bill.self, Ledger.self,
                                        configurations: .init(isStoredInMemoryOnly: true))
    let context = container.mainContext
    let ledger = Ledger(name: "测试账本")
    context.insert(ledger)

    // Act: Create
    let bill = Bill(amount: 100, type: .expense, categoryName: "餐饮")
    ledger.bills?.append(bill)
    try context.save()

    // Assert: 验证持久化
    let fetchedLedger = try context.fetch(FetchDescriptor<Ledger>()).first!
    XCTAssertEqual(fetchedLedger.bills?.count, 1)
    XCTAssertEqual(fetchedLedger.bills?.first?.amount, 100)

    // Act: Update
    fetchedLedger.bills?.first?.amount = 200
    try context.save()

    // Assert: 验证更新
    let updatedLedger = try context.fetch(FetchDescriptor<Ledger>()).first!
    XCTAssertEqual(updatedLedger.bills?.first?.amount, 200)

    // Act: Delete
    context.delete(fetchedLedger.bills!.first!)
    try context.save()

    // Assert: 验证删除
    let finalLedger = try context.fetch(FetchDescriptor<Ledger>()).first!
    XCTAssertEqual(finalLedger.bills?.count, 0)
}
```

### TC-004：分类统计百分比计算验证

```swift
func testCategoryStats_percentageCalculation_shouldBeCorrect() {
    // Arrange: 已知比例的账单
    let bills = [
        Bill(amount: 300, type: .expense, categoryName: "餐饮"),
        Bill(amount: 100, type: .expense, categoryName: "交通"),
        Bill(amount: 100, type: .expense, categoryName: "购物")
    ]
    // 总计 500，餐饮 60%，交通 20%，购物 20%

    // Act: 调用 StatisticsService.categoryStats（重构后）
    let stats = StatisticsService.categoryStats(from: bills, type: .expense)

    // Assert
    let foodStat = stats.first { $0.categoryName == "餐饮" }!
    XCTAssertEqual(foodStat.percentage, 60.0, accuracy: 0.01)

    let totalPercentage = stats.reduce(0) { $0 + $1.percentage }
    XCTAssertEqual(totalPercentage, 100.0, accuracy: 0.01)
}
```

### TC-005：清空数据危险操作防护测试

```swift
func testClearAllData_shouldRequireConfirmation() {
    // 此测试需要在 UI 测试层实现
    // 验证点击"清空所有数据"按钮时弹出确认对话框
    // 验证点击"取消"后数据未被删除
    // 验证点击"确认"后数据被清除

    // 在 ViewModel 层测试：
    // viewModel.requestClearAllData() → state.showConfirmClearAlert == true
    // viewModel.cancelClearAllData() → state.showConfirmClearAlert == false
    // viewModel.confirmClearAllData() → repository.deleteAll() called
}
```

### TC-006：搜索功能边界测试

```swift
func testSearch_withSpecialCharacters_shouldNotCrash() {
    let bills = [Bill(amount: 100, type: .expense, categoryName: "餐饮", note: "午餐")]

    // 测试特殊字符不崩溃
    let resultWith = bills.filter {
        $0.categoryName.localizedCaseInsensitiveContains("餐") ||
        ($0.note?.localizedCaseInsensitiveContains("餐") ?? false)
    }
    XCTAssertEqual(resultWith.count, 1)

    let resultEmpty = bills.filter {
        $0.categoryName.localizedCaseInsensitiveContains("") ||
        ($0.note?.localizedCaseInsensitiveContains("") ?? false)
    }
    // 空字符串搜索应返回所有结果（或定义其行为）
    XCTAssertEqual(resultEmpty.count, 1)
}
```

---

## 8. 质量验收标准

重构完成后，QA 将依据以下标准进行验收评估：

### 8.1 架构符合度标准

| 验收项 | 通过标准 | 检验方式 |
|--------|---------|---------|
| Repository 层 | 所有 SwiftData 操作封装在 Repository 协议实现中，View 层无直接 modelContext 调用 | 代码审查 |
| Service 层 | 所有业务逻辑（统计计算、数据验证、CSV 导出）移入 Service，View 层不含业务函数 | 代码审查 |
| ViewModel 层 | 每个主要视图有对应 ViewModel，`@Observable` 或 `ObservableObject` 实现 | 代码审查 |
| 代码重复 | `createDefaultCategories` 统一到一处，无明显重复代码块 | 代码审查 |
| 错误处理 | 所有 `try?` 替换为 `try`，有明确的错误传播或 UI 提示 | 代码审查 |

### 8.2 Bug 修复验收标准

| Bug ID | 验收标准 |
|--------|---------|
| BUG-01 | `TimeRange.year.dateRange()` 的 end 日期必须是 12 月 31 日 23:59:59（或等效值），通过 `testTimeRangeYear_endDate_shouldBeDecember31st` |
| BUG-02 | 清空数据操作弹出确认 Alert，取消后数据不删除，通过对应测试 |
| BUG-04/05 | 周/月的 end 日期包含当天全天，通过 `testFilterByTimeRange_xxx_shouldIncludeLastDayBills` |
| BUG-07 | 首次启动逻辑处理 UserDefaults 残留问题 |

### 8.3 测试覆盖率标准

| 层次 | 最低覆盖率目标 | 说明 |
|------|-------------|------|
| Repository 层 | 90%+ | 核心 CRUD 所有路径 |
| Service 层 | 85%+ | 包含边界条件 |
| ViewModel 层 | 80%+ | 主要状态变更路径 |
| Extension/Utility | 90%+ | 纯函数应全覆盖 |
| View 层 | 不作强制要求 | 以集成测试替代 |
| **整体** | **>75%** | Xcode Coverage 报告 |

### 8.4 编译与测试通过标准

| 标准 | 要求 |
|------|------|
| 编译 | `xcodebuild build` 零 Warning，零 Error |
| 单元测试 | 全部 `PASSED`，无跳过 |
| 集成测试 | 全部 `PASSED`，无跳过 |
| 性能测试 | 关键性能测试基线通过 |

### 8.5 性能基线标准

| 场景 | 基线要求 |
|------|---------|
| 100 条账单列表渲染 | < 100ms |
| 切换时间范围（重新统计） | < 200ms |
| 年度 dailyStats 计算（365天×100条账单） | < 500ms |
| 应用冷启动至首屏显示 | < 1.5s |

### 8.6 UI/UX 规范符合度标准

| 标准 | 要求 |
|------|------|
| 颜色 Token | 所有视图颜色使用 `AppColors.*` 或 `DesignSystem` 定义，无内联硬编码 |
| 圆角 Token | 所有圆角使用 `AppCornerRadius.*`，无硬编码数值（允许特殊情况说明原因） |
| 字体规范 | 金额显示使用 `.monospacedDigit()`，主要金额使用 `.rounded` design |
| 危险操作 | 删除/清空操作均有二次确认 Alert |
| 错误反馈 | 保存失败等错误有用户可见的提示 |

---

*报告生成时间：2026-04-03*
*报告版本：v1.0（Phase 1 初版）*
*下一步：等待同事三完成重构开发，检测 Repositories 目录创建后执行 Phase 2 评估*
