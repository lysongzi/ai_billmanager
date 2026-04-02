# BillManager 记账应用

一款简洁高效的 iOS/Mac 记账应用，帮助您轻松管理个人财务。

## 功能特性

- **多账本管理**：创建、编辑、删除、归档多个账本，支持自定义图标和颜色
- **账单记录**：支持收入/支出分类记账，含备注和日期
- **快捷记账**：快速金额 + 分类输入，分类自动过滤匹配账单类型
- **数据分析**：本周/本月/本年统计，支持饼图/趋势图可视化
- **设计系统**：统一的颜色、圆角、阴影规范，品牌色琥珀黄 (#F59E0B)
- **自定义导航**：自定义导航栏组件（CustomNavBar）和底部标签栏（BottomNavBar）

## 技术栈

| 技术 | 说明 |
|------|------|
| SwiftUI | 跨平台声明式 UI 框架 |
| SwiftData | Apple 新一代 ORM，@Model 驱动持久化 |
| Swift Charts | 原生图表框架，用于统计视图 |
| XCTest | 单元测试框架 |
| XcodeGen | 通过 project.yml 生成 .xcodeproj |
| MVVM | 架构模式 |

## 项目结构

```
BillManager/
├── App/                      # 应用入口
│   ├── BillManagerApp.swift
│   └── ContentView.swift
├── Models/                   # 数据模型（SwiftData @Model）
│   ├── Ledger.swift          # 账本
│   ├── Bill.swift            # 账单（含 BillType 枚举）
│   ├── Category.swift        # 分类
│   └── Statistics.swift      # 统计辅助模型
├── Views/                    # 视图层
│   ├── Ledgers/              # 账本列表
│   ├── Bills/                # 账单列表、添加、编辑
│   ├── Statistics/           # 统计分析
│   └── Settings/             # 设置
├── Components/               # 可复用 UI 组件
│   ├── CustomNavBar.swift    # 自定义导航栏（支持左/右插槽）
│   └── BottomNavBar.swift    # 底部标签栏
├── Utilities/                # 工具类
│   ├── DesignSystem.swift    # 颜色、圆角、阴影设计规范
│   └── Extensions.swift      # Swift/SwiftUI 扩展
└── Resources/                # 资源文件
    └── Assets.xcassets

BillManagerTests/             # 单元测试
├── ModelTests.swift          # 数据模型测试
├── StatisticsTests.swift     # 统计逻辑测试
└── ExtensionTests.swift      # 工具扩展测试
```

## 环境要求

- iOS 17.0+ / macOS 14.0+
- Xcode 15.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)（可选，用于从 project.yml 生成项目）

## 运行项目

1. 克隆项目
   ```bash
   git clone https://github.com/lysongzi/ai_billmanager.git
   cd ai_billmanager
   ```

2. （可选）使用 XcodeGen 重新生成项目文件
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
| 1.2.0 | UI 升级：设计系统、自定义导航栏、交互优化 |
| 1.1.0 | 添加单元测试框架（ModelTests、StatisticsTests、ExtensionTests） |
| 1.0.0 | 初始版本：账本管理、账单 CRUD、统计分析 |

## 许可证

MIT License
