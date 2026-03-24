# AI BillManager UI与交互重新设计技术实现方案

## 一、项目背景与目标

### 1.1 项目背景

AI BillManager 是一款基于 SwiftUI + SwiftData 构建的跨平台（iOS/Mac）记账应用。当前版本已实现核心功能：
- 多账本管理
- 账单 CRUD 操作
- 快捷记账
- 统计分析（饼图、折线图）
- 数据导出

### 1.2 设计目标

结合鲨鱼记账竞品分析和当前代码实现，重新设计的目标为：

| 目标 | 说明 |
|------|------|
| 提升iOS原生感 | 采用iOS原生设计规范，克制使用品牌元素 |
| 高效记账 | 优化记账流程，支持快捷金额输入+分类选择 |
| 财务专业感 | 建立清晰的数字排版体系，支出/收入语义色分离 |
| 信息组织 | 图表页卡片化，减少认知负担 |

### 1.3 现有UI问题（来自鲨鱼记账分析）

| 维度 | 主要问题 |
|------|----------|
| 品牌表达 | 黄色使用过强，品牌色与数据色混淆 |
| 层级系统 | 页面主次关系不够稳定 |
| 财务气质 | 缺少稳健、可信、专业的金融产品感 |
| 图表设计 | 数据可读性和层次组织仍可加强 |
| 高效记账 | 录入流程效率可进一步优化 |

---

## 二、现有实现分析

### 2.1 当前代码实现情况

**已完成功能：**
- TabView 导航（账本/统计/设置）
- 账本列表与创建
- 账单列表（日期分组、搜索、筛选）
- 完整记账编辑器 + 快捷记账浮窗
- 统计分析（时间维度切换、饼图、折线图）
- 设置页（货币、日期格式、数据导出）
- DesignSystem 色彩/字体/间距系统

**现有UI问题：**
- 顶部黄色块过于突出
- 首页信息堆砌
- 记账流程金额输入区不够突出
- 图表页筛选层级复杂

---

## 三、设计原则

### 3.1 核心关键词

**原生 · 克制 · 高效 · 清晰 · 可信**

### 3.2 视觉策略

- 保留品牌黄，但仅作为强调色（按钮、选中态、徽标）
- 页面背景回归浅暖白（#F7F7F5）与纯白卡片系统
- 支出与收入建立明确语义色（红/绿）体系
- 图表中黄色只作为强调色，每张图表最多5-6种主色

### 3.3 交互策略

- 高频任务优先：记账必须最快
- 数据展示卡片化：一张卡只解决一个分析问题
- 搜索与筛选前置：提升账单查找效率
- 层级精简：减少顶部复杂筛选带来的认知负担

---

## 四、信息架构设计

### 4.1 导航结构

**保持现有3-Tab结构（优化内容）：**

| Tab | 名称 | 功能 |
|-----|------|------|
| 1 | 账本 | 首页Dashboard + 账单明细（合并展示） |
| 2 | 统计 | 趋势、分类分析 |
| 3 | 设置 | 账本管理、通用设置、数据导出 |

**优化说明：**
- Tab1 融合首页与账单明细，避免频繁页面跳转
- 账本管理入口移至设置页
- 记账通过Tab中间FAB按钮快速触发

---

## 五、视觉设计系统

### 5.1 色彩系统（基于现有DesignSystem优化）

| 类别 | 颜色名称 | Hex值 | 用途 |
|------|----------|-------|------|
| 品牌色 | Brand Yellow | #F6C744 | 主按钮、选中态、高亮提示 |
| 语义色 | Expense Red | #F05A5A | 支出金额 |
| 语义色 | Income Green | #22B573 | 收入金额 |
| 语义色 | Info Blue | #5B7CFA | 信息提示 |
| 语义色 | Warning Orange | #F59E0B | 预算警告 |
| 中性色 | Background | #F7F7F5 | 页面背景 |
| 中性色 | Surface | #FFFFFF | 卡片背景 |
| 中性色 | Text Primary | #121212 | 主文字 |
| 中性色 | Text Secondary | #6B7280 | 辅助文字 |
| 中性色 | Line | #E9E9E7 | 分割线 |

### 5.2 字体排版

| 层级 | 用途 | 字号/字重 |
|------|------|-----------|
| Display XL | 总金额、核心数字 | 36/Semibold |
| Display L | 卡片金额 | 28/Semibold |
| H1 | 页面主标题 | 28/Bold |
| H2 | 模块标题 | 20/Semibold |
| H3 | 卡片标题 | 17/Semibold |
| Body | 正文/列表 | 15/Regular |
| Caption | 辅助信息 | 12/Regular |

### 5.3 间距与圆角

- 页面左右边距：20
- 卡片内边距：16/20
- 模块间距：20/24
- 列表单元高度：68
- 大卡片圆角：24
- 标准卡片圆角：20
- 按钮圆角：16

---

## 六、核心页面设计

### 6.1 首页重构（DashboardView）

**设计要点：**
- 顶部：账本切换 + 月份选择
- 财务总览卡：收入/支出/结余三列，语义色区分
- 快捷操作区：记一笔/转账/预算/导入
- 最近账单：显示最近5条，右上角"查看全部"
- 洞察卡：自动生成的财务洞察

**与现有代码对比：**
- 现有：顶部大面积黄色块
- 新版：白色卡片 + 品牌黄仅用于按钮和强调元素

### 6.2 记账页优化（QuickAddView）

**设计要点：**
- 金额输入为页面视觉中心（大字号56pt）
- 分类选择：横向滚动"最近使用"，下方"全部分类"
- 高级字段默认折叠
- 保存按钮固定底部安全区上方
- 支持"继续记一笔"快速连续记账

**与现有代码对比：**
- 现有：分类网格在上，金额输入区在下
- 新版：金额优先，分类辅助

### 6.3 统计页优化（StatisticsView）

**设计要点：**
- 顶部筛选：类型/时间维度
- 每个分析模块独立卡片（趋势图卡/分类分布卡）
- 卡片标题清晰，数据分组明确
- 简化筛选层级

**与现有代码对比：**
- 现有：筛选复杂，图表堆砌
- 新版：卡片化组织，点击交互增强

### 6.4 设置页优化（SettingsView）

**设计要点：**
- 使用 iOS grouped inset list 结构
- 分组：账本/通用/数据/关于
- 安全类功能放置靠前

---

## 七、技术实现方案

### 7.1 架构设计

```
┌─────────────────────────────────────────────────────────────┐
│                      Views (SwiftUI)                         │
│  Dashboard / BillList / QuickAdd / Statistics / Settings    │
├─────────────────────────────────────────────────────────────┤
│                    ViewModels (@Observable)                  │
│  DashboardVM / BillVM / StatisticsVM / SettingsVM          │
├─────────────────────────────────────────────────────────────┤
│                      Models (SwiftData)                      │
│  Ledger / Bill / Category / Statistics                      │
├─────────────────────────────────────────────────────────────┤
│                      Services                                │
│  DataService / ChartService / ExportService                 │
└─────────────────────────────────────────────────────────────┘
```

### 7.2 目录结构

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
├── ViewModels/
│   ├── DashboardViewModel.swift
│   ├── BillViewModel.swift
│   └── StatisticsViewModel.swift
├── Views/
│   ├── Dashboard/
│   │   ├── DashboardView.swift
│   │   ├── FinancialOverviewCard.swift
│   │   └── RecentBillsCard.swift
│   ├── Bills/
│   │   ├── BillListView.swift
│   │   ├── BillEditorView.swift
│   │   └── QuickAddView.swift
│   ├── Statistics/
│   │   └── StatisticsView.swift
│   ├── Settings/
│   │   └── SettingsView.swift
│   └── Components/
│       └── AmountInputView.swift
├── Services/
│   └── DataService.swift
├── Utilities/
│   ├── Extensions.swift
│   ├── DesignSystem.swift
│   └── Constants.swift
└── Resources/
    └── Assets.xcassets
```

---

## 八、实现优先级计划

### Phase 1：视觉与结构重构

| 任务 | 涉及文件 | 状态 |
|------|----------|------|
| 优化 DesignSystem 色彩系统 | DesignSystem.swift | 待实现 |
| 重构 DashboardView 首页 | DashboardView.swift | 待实现 |
| 优化 QuickAddView 记账流程 | BillEditorView.swift | 待实现 |
| 优化 StatisticsView 统计页 | StatisticsView.swift | 待实现 |
| 优化 SettingsView 设置页 | SettingsView.swift | 待实现 |

### Phase 2：交互增强

| 任务 | 涉及文件 | 状态 |
|------|----------|------|
| 账单搜索和高级筛选 | BillListView.swift | 待实现 |
| 最近使用分类功能 | BillEditorView.swift | 待实现 |
| 分类详情 drill-down | StatisticsView.swift | 待实现 |

### Phase 3：能力扩展

| 任务 | 状态 |
|------|------|
| 预算系统 | 后续版本 |
| 智能提醒 | 后续版本 |
| AI 语义记账 | 后续版本 |

---

## 九、验收标准

### 9.1 设计还原度

- [ ] 色彩系统符合设计规范（品牌黄仅用于强调）
- [ ] 字体排版层级清晰
- [ ] 卡片化设计一致
- [ ] 间距统一为4pt递进

### 9.2 功能完整性

- [ ] 账本管理功能正常
- [ ] 账单 CRUD 功能正常
- [ ] 快捷记账流程顺畅
- [ ] 统计图表正确展示
- [ ] 数据导出功能正常

### 9.3 性能要求

- [ ] 页面加载流畅，无明显卡顿
- [ ] 列表滚动帧率正常
- [ ] 图表渲染正确

---

## 十、变更记录

| 日期 | 版本 | 变更内容 |
|------|------|----------|
| 2026-03-24 | 1.0.0 | 初始版本：UI与交互重新设计技术方案 |