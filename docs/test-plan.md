# 记账应用测试方案

## 一、测试目标

1. 验证核心业务逻辑正确性
2. 确保数据模型操作符合预期
3. 保障统计分析计算准确
4. 回归测试防止功能退化

## 二、测试环境

- **Xcode**: 15.0+
- **iOS**: 17.0+
- **macOS**: 14.0+
- **框架**: XCTest + Swift Testing

## 三、测试类型

### 3.1 单元测试

| 模块 | 测试内容 | 优先级 |
|------|----------|--------|
| Models | 数据模型初始化、属性计算 | P0 |
| Statistics | 统计计算逻辑 | P0 |
| TimeRange | 日期范围计算 | P1 |
| Extensions | 工具方法 | P1 |
| DataService | 数据操作 | P2 |

### 3.2 UI 测试

| 场景 | 测试内容 | 优先级 |
|------|----------|--------|
| 账本管理 | 创建/编辑/删除/归档流程 | P1 |
| 账单管理 | 增删改查流程 | P1 |
| 快捷记账 | 快速添加账单 | P2 |
| 统计页面 | 图表渲染、数据筛选 | P2 |

## 四、测试用例

### 4.1 Model 测试

#### LedgerTests

```swift
// 初始化测试
func testLedgerInitialization() {
    let ledger = Ledger(name: "测试账本", icon: "book.fill", colorHex: "#007AFF")
    XCTAssertEqual(ledger.name, "测试账本")
    XCTAssertEqual(ledger.icon, "book.fill")
    XCTAssertEqual(ledger.colorHex, "#007AFF")
    XCTAssertFalse(ledger.isArchived)
}

// 计算属性测试
func testLedgerTotalIncome() {
    let ledger = Ledger(name: "测试")
    ledger.bills = [
        Bill(amount: 100, type: .income, categoryName: "工资"),
        Bill(amount: 50, type: .expense, categoryName: "餐饮")
    ]
    XCTAssertEqual(ledger.totalIncome, 100)
}

func testLedgerBalance() {
    let ledger = Ledger(name: "测试")
    ledger.bills = [
        Bill(amount: 1000, type: .income, categoryName: "工资"),
        Bill(amount: 300, type: .expense, categoryName: "餐饮")
    ]
    XCTAssertEqual(ledger.balance, 700)
}
```

#### BillTests

```swift
// 初始化测试
func testBillInitialization() {
    let bill = Bill(
        amount: 100.50,
        type: .expense,
        categoryName: "餐饮",
        categoryIcon: "fork.knife",
        categoryColorHex: "#FF6B6B"
    )
    XCTAssertEqual(bill.amount, 100.50)
    XCTAssertEqual(bill.type, .expense)
    XCTAssertEqual(bill.categoryName, "餐饮")
}

// 类型转换测试
func testBillTypeConversion() {
    let bill = Bill(amount: 100, type: .income, categoryName: "工资")
    XCTAssertEqual(bill.typeRawValue, "income")
    
    bill.type = .expense
    XCTAssertEqual(bill.typeRawValue, "expense")
}
```

#### CategoryTests

```swift
func testCategoryInitialization() {
    let category = Category(
        name: "餐饮",
        icon: "fork.knife",
        colorHex: "#FF6B6B",
        type: .expense
    )
    XCTAssertEqual(category.name, "餐饮")
    XCTAssertEqual(category.type, .expense)
}
```

### 4.2 Statistics 测试

#### StatisticsCalcTests

```swift
func testCategoryStatPercentage() {
    let stats = [
        CategoryStat(
            categoryName: "餐饮",
            icon: "fork.knife",
            colorHex: "#FF6B6B",
            amount: 50,
            percentage: 50,
            type: .expense
        ),
        CategoryStat(
            categoryName: "交通",
            icon: "car.fill",
            colorHex: "#4ECDC4",
            amount: 50,
            percentage: 50,
            type: .expense
        )
    ]
    
    let total = stats.reduce(0) { $0 + $1.amount }
    XCTAssertEqual(total, 100)
}
```

#### TimeRangeTests

```swift
func testWeekDateRange() {
    let (start, end) = TimeRange.week.dateRange()
    let calendar = Calendar.current
    
    // 验证开始日期是周一
    let weekday = calendar.component(.weekday, from: start)
    XCTAssertEqual(weekday, 2) // Sunday = 1, Monday = 2
    
    // 验证跨度为7天
    let daysDiff = calendar.dateComponents([.day], from: start, to: end).day
    XCTAssertEqual(daysDiff, 6)
}

func testMonthDateRange() {
    let (start, end) = TimeRange.month.dateRange()
    let calendar = Calendar.current
    
    // 验证开始日期是当月1号
    let day = calendar.component(.day, from: start)
    XCTAssertEqual(day, 1)
    
    // 验证结束日期是当月最后一天
    let range = calendar.range(of: .day, in: .month, for: start)!
    XCTAssertEqual(calendar.component(.day, from: end), range.count)
}

func testYearDateRange() {
    let (start, end) = TimeRange.year.dateRange()
    let calendar = Calendar.current
    
    // 验证开始日期是1月1号
    let month = calendar.component(.month, from: start)
    XCTAssertEqual(month, 1)
    
    // 验证结束日期是12月31号
    let endMonth = calendar.component(.month, from: end)
    let endDay = calendar.component(.day, from: end)
    XCTAssertEqual(endMonth, 12)
    XCTAssertEqual(endDay, 31)
}
```

### 4.3 Extensions 测试

#### DoubleExtensionsTests

```swift
func testCurrencyFormatted() {
    let amount1 = 100.0
    XCTAssertEqual(amount1.currencyFormatted, "¥100.00")
    
    let amount2 = 1234.56
    XCTAssertEqual(amount2.currencyFormatted, "¥1,234.56")
    
    let amount3 = 0
    XCTAssertEqual(amount3.currencyFormatted, "¥0.00")
}

func testZeroCurrencyFormatted() {
    let amount = 0.0
    let formatted = amount.currencyFormatted
    XCTAssertTrue(formatted.contains("0.00"))
}
```

#### DateExtensionsTests

```swift
func testDateStartOfDay() {
    let date = Date()
    let startOfDay = date.startOfDay
    let calendar = Calendar.current
    
    XCTAssertEqual(calendar.component(.hour, from: startOfDay), 0)
    XCTAssertEqual(calendar.component(.minute, from: startOfDay), 0)
    XCTAssertEqual(calendar.component(.second, from: startOfDay), 0)
}

func testDateIsToday() {
    let today = Date()
    XCTAssertTrue(today.isToday)
    
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    XCTAssertFalse(yesterday.isToday)
}

func testDateIsYesterday() {
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    XCTAssertTrue(yesterday.isYesterday)
    
    let today = Date()
    XCTAssertFalse(today.isYesterday)
}

func testDateRelativeDescription() {
    let today = Date()
    XCTAssertEqual(today.relativeDescription, "今天")
    
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    XCTAssertEqual(yesterday.relativeDescription, "昨天")
}

func testDateFormatted() {
    let date = Date()
    let formatted = date.formatted(as: "yyyy-MM-dd")
    
    // 验证格式包含年份、月份、日期
    XCTAssertTrue(formatted.contains("-"))
}
```

#### ArrayExtensionsTests

```swift
func testBillGroupedByDate() {
    let calendar = Calendar.current
    let today = Date()
    let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
    
    let bills = [
        Bill(amount: 100, type: .expense, categoryName: "餐饮", date: today),
        Bill(amount: 50, type: .expense, categoryName: "交通", date: today),
        Bill(amount: 200, type: .income, categoryName: "工资", date: yesterday)
    ]
    
    let grouped = bills.groupedByDate()
    
    XCTAssertEqual(grouped.count, 2)
    
    let todayBills = grouped.first { calendar.isDate($0.date, inSameDayAs: today) }?.bills
    XCTAssertEqual(todayBills?.count, 2)
}

func testBillFilteredByTimeRange() {
    let bills = [
        Bill(amount: 100, type: .expense, categoryName: "餐饮", date: Date()),
        Bill(amount: 50, type: .expense, categoryName: "交通", date: Date())
    ]
    
    let filtered = bills.filtered(by: .month)
    XCTAssertEqual(filtered.count, 2)
}

func testBillTotalIncome() {
    let bills = [
        Bill(amount: 1000, type: .income, categoryName: "工资"),
        Bill(amount: 500, type: .income, categoryName: "奖金"),
        Bill(amount: 100, type: .expense, categoryName: "餐饮")
    ]
    
    XCTAssertEqual(bills.totalIncome(in: .month), 1500)
}

func testBillTotalExpense() {
    let bills = [
        Bill(amount: 1000, type: .income, categoryName: "工资"),
        Bill(amount: 100, type: .expense, categoryName: "餐饮"),
        Bill(amount: 50, type: .expense, categoryName: "交通")
    ]
    
    XCTAssertEqual(bills.totalExpense(in: .month), 150)
}
```

## 五、测试数据

### 5.1 测试用账本

```swift
func createTestLedger() -> Ledger {
    Ledger(name: "测试账本", icon: "book.fill", colorHex: "#007AFF")
}
```

### 5.2 测试用账单

```swift
func createTestBills() -> [Bill] {
    let calendar = Calendar.current
    let today = Date()
    let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
    let lastWeek = calendar.date(byAdding: .day, value: -7, to: today)!
    
    return [
        Bill(amount: 5000, type: .income, categoryName: "工资", date: today),
        Bill(amount: 1000, type: .income, categoryName: "奖金", date: yesterday),
        Bill(amount: 50, type: .expense, categoryName: "餐饮", date: today),
        Bill(amount: 30, type: .expense, categoryName: "交通", date: today),
        Bill(amount: 20, type: .expense, categoryName: "通讯", date: lastWeek)
    ]
}
```

### 5.3 测试用分类

```swift
func createTestCategories() -> [Category] {
    [
        Category(name: "餐饮", icon: "fork.knife", colorHex: "#FF6B6B", type: .expense),
        Category(name: "交通", icon: "car.fill", colorHex: "#4ECDC4", type: .expense),
        Category(name: "工资", icon: "banknote.fill", colorHex: "#2ECC71", type: .income)
    ]
}
```

## 六、测试执行

### 6.1 运行所有测试

```bash
xcodebuild test -scheme BillManager -destination 'platform=iOS Simulator,name=iPhone 15'
```

### 6.2 运行特定测试类

```bash
xcodebuild test -scheme BillManager -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:BillManagerTests/LedgerTests
```

### 6.3 生成测试覆盖率报告

```bash
xcodebuild test -scheme BillManager -destination 'platform=iOS Simulator,name=iPhone 15' -enableCodeCoverage YES
```

## 七、测试验收标准

| 类型 | 覆盖率目标 | 通过率目标 |
|------|------------|------------|
| 单元测试 | 70%+ | 100% |
| UI测试 | - | 核心流程通过 |

## 八、后续计划

1. 添加 ViewModel 测试
2. 添加 Service 层测试
3. 添加 UI 自动化测试
4. 集成 CI/CD 测试流程