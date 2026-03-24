# BillManager 记账应用

一款简洁高效的跨平台 iOS/Mac 记账应用，帮助您轻松管理个人财务。

## 功能特性

### 核心功能
- **多账本管理**：创建、编辑、删除、归档多个账本
- **账单记录**：支持收入/支出分类记账
- **快捷记账**：FAB按钮快速金额+分类输入，支持连续记账
- **数据分析**：本周/本月/本年统计，饼图/趋势图可视化
- **预算管理**：设置月度/周度/年预算，跟踪支出进度
- **标签管理**：为账单添加自定义标签，便于分类整理

### 导航结构（5-Tab）

| Tab | 名称 | 功能 |
|-----|------|------|
| Tab 1 | 明细 | Dashboard首页（账本切换+月份选择+收支概览+账单列表） |
| Tab 2 | 图表 | 统计分析（饼图、折线图、分类明细） |
| Tab 3 | 记账 | FAB快捷记账按钮 |
| Tab 4 | 发现 | 预算管理、资产概览、智能洞察 |
| Tab 5 | 我的 | 账本管理、分类管理、标签管理、设置 |

### 功能截图

| 明细首页 | 图表统计 | 发现页 | 我的 |
|---------|---------|--------|------|
| ![明细](https://via.placeholder.com/150) | ![统计](https://via.placeholder.com/150) | ![发现](https://via.placeholder.com/150) | ![我的](https://via.placeholder.com/150) |

## 技术栈

| 技术 | 说明 |
|------|------|
| SwiftUI | 跨平台声明式 UI 框架 |
| SwiftData | Apple 新一代 ORM |
| Swift Charts | 原生图表框架 |
| MVVM | 架构模式 |

## 项目结构

```
BillManager/
├── App/                      # 应用入口
│   ├── BillManagerApp.swift
│   └── ContentView.swift     # 5-Tab导航 + FAB按钮
├── Models/                   # 数据模型
│   ├── Ledger.swift          # 账本
│   ├── Bill.swift            # 账单
│   ├── Category.swift        # 分类
│   ├── Budget.swift          # 预算（新增）
│   ├── Tag.swift             # 标签（新增）
│   └── Statistics.swift      # 统计数据
├── Views/                    # 视图层
│   ├── Dashboard/
│   │   └── DashboardView.swift   # 首页（财务总览+账单列表）
│   ├── Budget/
│   │   └── BudgetView.swift      # 发现页（预算+资产+洞察）
│   ├── Statistics/
│   │   └── StatisticsView.swift  # 统计页
│   ├── Bills/
│   │   ├── BillListView.swift    # 账单列表
│   │   ├── BillEditorView.swift  # 账单编辑器
│   │   └── QuickAddView.swift    # 快捷记账
│   ├── Ledgers/
│   │   └── LedgerListView.swift  # 账本管理
│   └── Profile/
│       ├── ProfileView.swift         # 我的页面
│       ├── TagManagementView.swift   # 标签管理
│       └── CategoryManagementView.swift # 分类管理
├── ViewModels/               # 视图模型
├── Services/                 # 服务层
├── Utilities/                # 工具类
│   ├── Extensions.swift      # 扩展方法
│   └── DesignSystem.swift    # 设计系统
└── Resources/                # 资源文件
    └── Assets.xcassets
```

## 环境要求

- iOS 17.0+
- macOS 14.0+
- Xcode 15.0+

## 运行项目

1. 克隆项目
   ```bash
   git clone https://github.com/lysongzi/ai_billmanager.git
   cd ai_billmanager
   ```

2. 使用 XcodeGen 生成项目
   ```bash
   xcodegen generate
   ```

3. 用 Xcode 打开并运行
   ```bash
   open BillManager.xcodeproj
   ```

## 版本历史

| 版本 | 更新内容 |
|------|----------|
| 1.0.0 | 初始版本：账本管理、账单 CRUD、统计分析 |
| 2.1.0 | 5-Tab导航、FAB快捷记账、预算管理、标签管理、分类管理 |

## 许可证

MIT License