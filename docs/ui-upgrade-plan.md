# 记账应用 UI 升级技术方案设计

## 一、现状分析

### 1.1 现有代码架构

| 模块 | 当前实现 |
|------|----------|
| 框架 | SwiftUI + SwiftData |
| 导航 | TabView (3个Tab) |
| 布局 | 标准全屏布局 |
| 色彩 | 系统蓝色 (#007AFF) 为主 |
| 卡片 | 标准圆角 + 阴影 |

### 1.2 原型设计特点

| 特性 | 原型设计 | 现有实现 |
|------|----------|----------|
| 布局 | 手机尺寸居中 (max-w-md) | 全屏宽度 |
| 配色 | stone/amber/rose 暖色调 | 系统蓝色 |
| 导航 | 底部导航 + 悬浮加号按钮 | TabView |
| 首页 | 搜索条 + 汇总卡片 + 账单流 | 账本卡片入口 |
| 记账 | 大数字输入 + 分类网格 | 传统表单 |
| 统计 | 胶囊筛选 + 环形饼图 | 标准图表 |
| 设置 | 分组圆角卡片 | 标准 List |

---

## 二、升级方案

### 2.1 设计系统统一

#### 颜色系统

```swift
// 温暖色调设计系统
struct AppColors {
    // 主色调 - 琥珀色
    static let primary = Color(hex: "#F59E0B")      // amber-500
    static let primaryLight = Color(hex: "#FCD34D") // amber-300
    static let primaryDark = Color(hex: "#D97706")  // amber-600
    
    // 背景色 - stone 系列
    static let background = Color(hex: "#FAFAF9")   // stone-50
    static let backgroundAlt = Color(hex: "#F5F5F4") // stone-100
    static let cardBackground = Color.white
    
    // 文字色
    static let textPrimary = Color(hex: "#1C1917")  // stone-800
    static let textSecondary = Color(hex: "#A8A29E") // stone-400
    static let textTertiary = Color(hex: "#78716C") // stone-500
    
    // 功能色
    static let income = Color(hex: "#10B981")       // emerald-500
    static let expense = Color(hex: "#F43F5E")      // rose-500
    static let balance = Color(hex: "#F59E0B")      // amber-500
}
```

#### 圆角系统

```swift
struct AppCornerRadius {
    static let small: CGFloat = 8      // 小元素
    static let medium: CGFloat = 16    // 中等卡片
    static let large: CGFloat = 24     // 大卡片
    static let extraLarge: CGFloat = 40 // 页面级容器
}
```

#### 阴影系统

```swift
struct AppShadows {
    static let card = Color.black.opacity(0.04)
    static let cardHover = Color.black.opacity(0.08)
    static let button = Color(hex: "#F59E0B").opacity(0.3)
}
```

---

### 2.2 页面改造清单

#### 2.2.1 ContentView 导航重构

| 现有 | 改造后 |
|------|--------|
| TabView | 自定义底部导航栏 |
| 标准图标 | 带动画的图标 + 圆点指示器 |
| 全屏宽度 | 居中布局 (maxWidth: 420) |

#### 2.2.2 首页 (HomeView) 改造

| 现有 | 改造后 |
|------|--------|
| NavigationStack | 自定义 Header |
| 账本卡片入口 | 账本选择器 + 搜索条 |
| 无汇总卡片 | 本月收支汇总卡片 |
| 账单列表 | 按日期分组的账单流 |

#### 2.2.3 记账页 (AddRecordView) 改造

| 现有 | 改造后 |
|------|--------|
| Sheet 弹出 | 全屏页面 |
| 标准金额输入 | 大字体金额输入 (48pt) |
| 收入/支出切换 | 胶囊式toggle |
| 分类选择器 | 4列网格分类 |

#### 2.2.4 统计页 (StatisticsView) 改造

| 现有 | 改造后 |
|------|--------|
| 标准时间选择器 | 胶囊式筛选 (本周/本月/本年) |
| 分段控制 | 收入/支出切换 |
| 标准卡片 | 圆角大卡片 + 顶部装饰线 |
| 饼图 | 环形图 + 中心汇总 |

#### 2.2.5 设置页 (SettingsView) 改造

| 现有 | 改造后 |
|------|--------|
| List 样式 | 分组圆角卡片 |
| 纯文字图标 | 彩色图标背景 |
| 标准分隔线 | 简洁分隔 |

#### 2.2.6 账本管理页 (LedgerListView) 改造

| 现有 | 改造后 |
|------|--------|
| ScrollView + VStack | 标准列表 |
| 卡片样式 | 大圆角卡片 + 悬浮效果 |

---

### 2.3 新增组件库

```
Components/
├── BottomNavBar.swift      // 自定义底部导航
├── LedgerPicker.swift      // 账本选择器
├── SearchBar.swift         // 搜索条
├── SummaryCard.swift       // 汇总卡片
├── TransactionCard.swift   // 账单卡片
├── CategoryGrid.swift      // 分类网格
├── AmountInput.swift       // 大金额输入
├── PeriodPicker.swift      // 时间胶囊筛选
├── SettingsSection.swift   // 设置分组
└── LedgerCard.swift        // 账本卡片
```

---

## 三、实施计划

### 阶段一：设计系统 (预计 1 天)

1. 创建 `DesignSystem.swift` 统一颜色/圆角/阴影
2. 更新现有组件使用新设计系统

### 阶段二：导航重构 (预计 0.5 天)

1. 创建 `CustomBottomNav`
2. 改造 `ContentView` 居中布局
3. 调整各页面适配

### 阶段三：首页改造 (预计 1 天)

1. 创建 `HomeView` 新布局
2. 实现账本选择器
3. 实现汇总卡片
4. 改造账单列表显示

### 阶段四：记账页改造 (预计 1 天)

1. 创建全屏 `AddRecordView`
2. 实现大金额输入
3. 实现分类网格
4. 对接现有数据逻辑

### 阶段五：统计页优化 (预计 0.5 天)

1. 改造筛选器样式
2. 优化图表展示

### 阶段六：设置页改造 (预计 0.5 天)

1. 分组卡片样式
2. 图标背景样式

### 阶段七：账本管理页改造 (预计 0.5 天)

1. 卡片样式优化
2. 新建账本流程

---

## 四、数据对接

所有 UI 改造保持现有数据模型不变：

```swift
// 现有模型继续使用
@Model class Ledger { ... }
@Model class Bill { ... }
@Model class Category { ... }
```

**对接要点：**
1. 搜索功能对接 BillListView 筛选逻辑
2. 记账页保存对接 BillEditorView 逻辑
3. 统计页数据对接现有统计计算

---

## 五、验收标准

1. 设计风格统一为暖色调 (stone/amber)
2. 布局改为居中手机尺寸 (420pt 宽)
3. 底部导航带动画效果
4. 记账页支持大金额输入和分类网格
5. 统计页使用胶囊筛选器
6. 设置页使用分组卡片样式
7. 现有数据功能完全兼容

---

## 六、实施情况

### 已完成 (v1.0)

| 组件 | 状态 | 文件 |
|------|------|------|
| 设计系统 | ✅ | `BillManager/Utilities/DesignSystem.swift` |
| 自定义底部导航栏 | ✅ | `BillManager/Components/BottomNavBar.swift` |
| 记账页 | ✅ | `BillManager/Views/Bills/AddRecordView.swift` |

### 设计系统实现

```swift
// 颜色系统 - 温暖色调 (amber/stone)
struct AppColors {
    static let primary = Color(red: 245/255, green: 158/255, blue: 11/255)    // 琥珀色
    static let background = Color(red: 250/255, green: 250/255, blue: 249/255) // stone-50
    static let income = Color(red: 16/255, green: 185/255, blue: 129/255)      // emerald-500
    static let expense = Color(red: 244/255, green: 63/255, blue: 94/255)      // rose-500
}

// 圆角系统
struct AppCornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let extraLarge: CGFloat = 40
}
```

### 组件特性

**BottomNavBar**
- 自定义底部导航栏，带动画效果
- 选中状态使用琥珀色主色调
- 圆点指示器动画

**AddRecordView**
- 大字体金额输入 (44pt)
- 胶囊式收入/支出切换
- 4列分类网格
- 日期时间选择器
- 备注输入

---

## 七、构建验证

```
✅ BUILD SUCCEEDED
✅ TEST SUCCEEDED - 21 tests passed
```

---

## 八、后续计划

| 版本 | 功能 |
|------|------|
| v1.1 | 首页改造 (HomeView) - 账本选择器、搜索条、汇总卡片 |
| v1.2 | 统计页样式优化 |
| v1.3 | 设置页卡片样式改造 |
| v1.4 | 账本管理页样式改造 |
