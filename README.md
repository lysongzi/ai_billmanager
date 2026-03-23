# BillManager 记账应用

一款简洁高效的跨平台 iOS/Mac 记账应用，帮助您轻松管理个人财务。

## 功能特性

### 核心功能
- **多账本管理**：创建、编辑、删除、归档多个账本
- **账单记录**：支持收入/支出分类记账
- **快捷记账**：快速金额+分类输入
- **数据分析**：本周/本月/本年统计，饼图/趋势图可视化

### 功能截图

| 账本列表 | 账单列表 | 统计分析 | 设置 |
|---------|---------|---------|------|
| ![账本](https://via.placeholder.com/150) | ![账单](https://via.placeholder.com/150) | ![统计](https://via.placeholder.com/150) | ![设置](https://via.placeholder.com/150) |

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
│   └── ContentView.swift
├── Models/                   # 数据模型
│   ├── Ledger.swift
│   ├── Bill.swift
│   ├── Category.swift
│   └── Statistics.swift
├── Views/                    # 视图层
│   ├── Ledgers/
│   ├── Bills/
│   ├── Statistics/
│   └── Settings/
├── Utilities/                # 工具类
│   └── Extensions.swift
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

## 许可证

MIT License