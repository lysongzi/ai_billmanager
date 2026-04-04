# BillManager UI 设计规范文档

**版本**: v1.0
**日期**: 2026-04-03
**设计师**: UI/UX 设计团队
**适用平台**: iOS 17+
**技术栈**: SwiftUI + SwiftData

---

## 目录

1. [设计理念与风格定位](#1-设计理念与风格定位)
2. [色彩系统](#2-色彩系统color-system)
3. [字体系统](#3-字体系统typography-system)
4. [间距与圆角系统](#4-间距与圆角系统spacing--corner-radius)
5. [阴影系统](#5-阴影系统shadow-system)
6. [通用组件规范](#6-通用组件规范reusable-components)
7. [各页面 UI 规范](#7-各页面-ui-规范)
8. [交互动效规范](#8-交互动效规范)
9. [iOS 适配规范](#9-ios-适配规范)

---

## 1. 设计理念与风格定位

### 1.1 设计哲学

**"温暖克制，以数据为中心"**

BillManager 的设计核心是将财务数据以最清晰、最直观的方式呈现给用户，同时通过暖色调营造一种"管理财务并不沉重"的心理感受。设计上遵循以下三个原则：

- **克制（Restraint）**: 每个页面只保留最核心的信息与操作，避免信息过载。留白是设计的一部分，而非空缺。
- **温暖（Warmth）**: 以琥珀黄（Amber）为主色调，stone 系暖灰作为背景基调，让记账这件"理性"的事情带有一丝"人情味"。
- **清晰（Clarity）**: 金额数字使用等宽字体、醒目字号，收入与支出通过颜色语义严格区分，用户一眼即可判断财务状态。

### 1.2 用户体验目标

| 目标维度 | 具体指标 |
|---------|---------|
| **效率** | 快捷记账操作步骤不超过 3 步，从打开 App 到完成记账 ≤ 15 秒 |
| **可读性** | 最小文字尺寸不低于 12pt，关键数据字号不低于 16pt |
| **反馈性** | 所有交互操作在 200ms 内提供视觉反馈 |
| **一致性** | 同类组件在所有页面保持相同的视觉语言与交互模式 |
| **容错性** | 删除、归档等破坏性操作必须有确认流程，支持撤销 |

---

## 2. 色彩系统（Color System）

### 2.1 主色调（Primary Colors）

| 名称 | Token | HEX | 用途 |
|------|-------|-----|------|
| Primary | `primary` | `#F59E0B` | 主按钮、强调元素、激活状态、品牌色 |
| Primary Light | `primaryLight` | `#FCD34D` | 渐变高亮端、hover 态、浅色背景强调 |
| Primary Dark | `primaryDark` | `#D97706` | 渐变深色端、按下态、图标填充 |
| Primary Surface | `primarySurface` | `#FFFBEB` | 主色调浅背景（卡片 tint、选中行背景） |

**主色渐变**: `LinearGradient(colors: [#FCD34D, #F59E0B], startPoint: .topLeading, endPoint: .bottomTrailing)`

### 2.2 语义色（Semantic Colors）

| 名称 | Token | HEX | 用途 |
|------|-------|-----|------|
| 收入 | `income` | `#10B981` | 收入金额、收入标签、正向趋势 |
| 收入浅 | `incomeLight` | `#D1FAE5` | 收入标签背景、收入高亮区域 |
| 支出 | `expense` | `#F43F5E` | 支出金额、支出标签、负向趋势 |
| 支出浅 | `expenseLight` | `#FFE4E8` | 支出标签背景、支出高亮区域 |
| 余额 | `balance` | `#F59E0B` | 净余额展示（与 primary 一致） |
| 成功 | `success` | `#22C55E` | 操作成功提示、完成状态 |
| 警告 | `warning` | `#F97316` | 预算超支警告、注意提示 |
| 错误 | `error` | `#EF4444` | 错误提示、必填项警告 |
| 信息 | `info` | `#3B82F6` | 提示性信息、帮助文本 |

### 2.3 背景色（Background Colors）

| 名称 | Token | HEX | 用途 |
|------|-------|-----|------|
| 主背景 | `background` | `#FAFAF9` | 全局页面背景（stone-50） |
| 次要背景 | `backgroundAlt` | `#F5F5F4` | 分组区域背景、输入框背景（stone-100） |
| 卡片背景 | `cardBackground` | `#FFFFFF` | 所有卡片、Sheet、底部弹窗背景 |
| 分隔背景 | `backgroundTertiary` | `#E7E5E4` | 分割线颜色（stone-200） |

### 2.4 文字色（Text Colors）

| 名称 | Token | HEX | 用途 |
|------|-------|-----|------|
| 主文字 | `textPrimary` | `#1C1917` | 标题、正文、金额（stone-900） |
| 次要文字 | `textSecondary` | `#78716C` | 副标题、标签、描述文字（stone-500） |
| 辅助文字 | `textTertiary` | `#A8A29E` | 时间戳、次要说明（stone-400） |
| 占位符 | `textPlaceholder` | `#D6D3D1` | 输入框占位文字（stone-300） |
| 反色文字 | `textOnPrimary` | `#FFFFFF` | 主色按钮上的文字 |
| 链接文字 | `textLink` | `#F59E0B` | 可点击链接 |

### 2.5 暖色调辅助色（Warm Accent Colors）

| 名称 | Token | HEX | 用途 |
|------|-------|-----|------|
| 暖珊瑚 | `accentCoral` | `#FB923C` | 次级强调、Orange 分类图标 |
| 暖玫瑰 | `accentRose` | `#FB7185` | 支出相关强调 |
| 暖沙 | `accentSand` | `#FDE68A` | 背景装饰、卡片渐变 |
| 暖棕 | `accentBrown` | `#92400E` | 深色辅助文字 |

### 2.6 Swift 代码定义参考

```swift
extension Color {
    // Primary
    static let appPrimary       = Color(hex: "#F59E0B")
    static let appPrimaryLight  = Color(hex: "#FCD34D")
    static let appPrimaryDark   = Color(hex: "#D97706")
    static let appPrimarySurface = Color(hex: "#FFFBEB")

    // Semantic
    static let appIncome        = Color(hex: "#10B981")
    static let appIncomeLight   = Color(hex: "#D1FAE5")
    static let appExpense       = Color(hex: "#F43F5E")
    static let appExpenseLight  = Color(hex: "#FFE4E8")
    static let appSuccess       = Color(hex: "#22C55E")
    static let appWarning       = Color(hex: "#F97316")
    static let appError         = Color(hex: "#EF4444")

    // Background
    static let appBackground    = Color(hex: "#FAFAF9")
    static let appBackgroundAlt = Color(hex: "#F5F5F4")
    static let appCard          = Color.white
    static let appDivider       = Color(hex: "#E7E5E4")

    // Text
    static let appTextPrimary   = Color(hex: "#1C1917")
    static let appTextSecondary = Color(hex: "#78716C")
    static let appTextTertiary  = Color(hex: "#A8A29E")
    static let appPlaceholder   = Color(hex: "#D6D3D1")
}
```

---

## 3. 字体系统（Typography System）

### 3.1 字体家族

- **界面字体**: SF Pro（系统默认，自动启用）
- **数字专用字体**: SF Pro Rounded（数字展示更圆润友好）或 `.monospacedDigit()` 修饰符（保证数字等宽对齐）

### 3.2 字号规范

| 级别 | 用途 | 字号 | 字重 | 行高 | SwiftUI 对应 |
|------|------|------|------|------|-------------|
| Display | 大金额数字展示 | 40pt | Heavy (900) | 48pt | `.system(size: 40, weight: .heavy)` |
| H1 | 页面主标题 | 28pt | Bold (700) | 34pt | `.title` |
| H2 | 卡片标题、区块标题 | 22pt | Semibold (600) | 28pt | `.title2` |
| H3 | 列表主要信息 | 18pt | Semibold (600) | 24pt | `.title3` |
| H4 | 二级标题、分组标题 | 16pt | Medium (500) | 22pt | `.headline` |
| Body | 正文内容 | 16pt | Regular (400) | 24pt | `.body` |
| Body Sm | 次要正文 | 14pt | Regular (400) | 20pt | `.subheadline` |
| Caption | 辅助信息、时间戳 | 12pt | Regular (400) | 16pt | `.caption` |
| Caption Sm | 极小标注 | 10pt | Regular (400) | 14pt | `.caption2` |

### 3.3 金额数字专用规范

金额展示是记账应用的核心视觉元素，需特殊处理：

```swift
// 大金额展示（首页汇总卡片）
Text(amountString)
    .font(.system(size: 40, weight: .heavy, design: .rounded))
    .monospacedDigit()
    .foregroundColor(.appTextPrimary)

// 列表金额（账单列表行）
Text(amountString)
    .font(.system(size: 16, weight: .semibold, design: .rounded))
    .monospacedDigit()
    .foregroundColor(isExpense ? .appExpense : .appIncome)

// 输入框金额（记账输入）
Text(inputAmount)
    .font(.system(size: 48, weight: .bold, design: .rounded))
    .monospacedDigit()
```

**金额格式规范**:
- 始终显示货币符号（¥）
- 保留两位小数（¥1,234.56）
- 千分位分隔符（1,234,567.89）
- 负数支出不显示负号，使用红色区分；收入使用绿色

---

## 4. 间距与圆角系统（Spacing & Corner Radius）

### 4.1 间距规范

基础单位为 4pt（遵循 4pt 网格系统）：

| Token | 值 | 用途 |
|-------|---|------|
| `spacing1` | 4pt | 图标与文字间距、徽章内边距 |
| `spacing2` | 8pt | 列表行内元素间距、小组件内边距 |
| `spacing3` | 12pt | 标签内边距、小卡片内边距 |
| `spacing4` | 16pt | **标准间距**，卡片内边距、列表行垂直间距 |
| `spacing5` | 20pt | 卡片间距、组件间距 |
| `spacing6` | 24pt | 页面分区间距、大卡片内边距 |
| `spacing8` | 32pt | 页面水平边距（内容区左右留白） |
| `spacing10` | 40pt | 大分区间距 |
| `spacing12` | 48pt | 超大间距，Bottom Safe Area 补偿 |

**页面水平边距**: 左右各 `16pt`（标准），大屏幕适配时最大内容宽度 `428pt`。

### 4.2 圆角规范

| Token | 值 | 用途 |
|-------|---|------|
| `radiusXS` | 4pt | 标签、角标、小徽章 |
| `radiusSM` | 8pt | 输入框、小按钮、图标背景 |
| `radiusMD` | 12pt | 列表行、次要卡片 |
| `radiusLG` | 16pt | **标准卡片**，主要内容卡片 |
| `radiusXL` | 24pt | 大卡片、底部 Sheet |
| `radius2XL` | 32pt | 浮动按钮、大模态卡片 |
| `radiusFull` | 999pt | 胶囊形按钮、标签切换器、头像 |

```swift
struct AppRadius {
    static let xs:    CGFloat = 4
    static let sm:    CGFloat = 8
    static let md:    CGFloat = 12
    static let lg:    CGFloat = 16
    static let xl:    CGFloat = 24
    static let xxl:   CGFloat = 32
    static let full:  CGFloat = 999
}
```

---

## 5. 阴影系统（Shadow System）

所有阴影使用暖色调（微带琥珀色），避免纯冷灰阴影与整体暖色调冲突。

### 5.1 阴影规范

| 级别 | 用途 | Color | Opacity | Radius | X | Y |
|------|------|-------|---------|--------|---|---|
| **无阴影** | 背景内嵌内容 | - | 0 | 0 | 0 | 0 |
| **轻阴影** | 卡片、列表项悬浮 | `#92400E` | 0.06 | 8 | 0 | 2 |
| **标准阴影** | 主要卡片、浮动元素 | `#92400E` | 0.10 | 16 | 0 | 4 |
| **强调阴影** | 主按钮、FAB 悬浮 | `#F59E0B` | 0.30 | 20 | 0 | 8 |
| **底部栏阴影** | BottomTabBar 分隔 | `#1C1917` | 0.08 | 12 | 0 | -4 |

### 5.2 Swift 代码定义

```swift
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
```

---

## 6. 通用组件规范（Reusable Components）

---

### 6.1 PrimaryButton — 主按钮

**设计描述**: 使用主色调渐变背景的全宽或固定宽度按钮，用于页面最主要的确认操作。

**视觉规范**:
- 背景: 渐变 `[#FCD34D → #F59E0B]`，方向 topLeading → bottomTrailing
- 文字: 白色，16pt Semibold
- 高度: 52pt（标准），44pt（紧凑）
- 圆角: `radiusFull`（胶囊形）或 `radiusLG`（方形场景）
- 阴影: `shadowEmphasis()`（主色阴影）
- 按下态: 整体缩放至 0.97，亮度降低 5%
- 禁用态: 整体透明度 0.4，无阴影

**属性参数**:
```swift
struct PrimaryButton: View {
    let title: String
    let icon: String?          // SF Symbol 名称，可选
    let style: ButtonStyle     // .full（全宽）| .fixed（固定宽）
    let size: ButtonSize       // .standard（52pt）| .compact（44pt）
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void
}
```

**使用场景**: 保存账单、确认记账、创建账本、完成设置。

---

### 6.2 SecondaryButton — 次要按钮

**设计描述**: 透明/浅色背景的按钮，用于次要操作或与主按钮并列。

**视觉规范**:
- 背景变体 A（描边型）: 透明背景 + `appPrimary` 1pt 描边
- 背景变体 B（填充型）: `appPrimarySurface` 背景，无描边
- 文字: `appPrimary`，16pt Medium
- 高度: 52pt / 44pt（与主按钮对齐）
- 圆角: `radiusFull` 或 `radiusLG`
- 按下态: 背景加深至 `appPrimaryLight`
- 阴影: 无（区分主次层级）

**使用场景**: 取消操作、次要确认、返回、编辑（与保存并列）。

---

### 6.3 CardView — 通用卡片容器

**设计描述**: 统一的卡片容器，承载列表项、统计模块、表单区块等内容。

**视觉规范**:
- 背景: `appCard`（白色）
- 圆角: `radiusLG`（16pt）标准，`radiusXL`（24pt）大卡片
- 阴影: `shadowLight()`
- 内边距: `spacing4`（16pt）标准
- 描边: 可选 `appDivider` 0.5pt 描边（用于白底上的卡片区分）

**属性参数**:
```swift
struct CardView<Content: View>: View {
    let padding: CGFloat           // 默认 16
    let cornerRadius: CGFloat      // 默认 16
    let shadowLevel: ShadowLevel   // .none | .light | .standard
    let hasBorder: Bool            // 默认 false
    @ViewBuilder let content: () -> Content
}
```

**使用场景**: 账单列表行、统计卡片、快捷记账输入区、设置分组。

---

### 6.4 AmountDisplay — 金额展示组件

**设计描述**: 专为金额数字设计的展示组件，根据类型（收入/支出/余额/中性）自动应用颜色和格式。

**视觉规范**:
- 字体: SF Pro Rounded + `.monospacedDigit()`
- 收入: `appIncome`（绿色）+ 可选前置 "+"
- 支出: `appExpense`（红色）+ 可选前置 "-"（大尺寸不显示负号，小尺寸显示）
- 余额: `appPrimary`（琥珀黄）
- 中性: `appTextPrimary`
- 尺寸 Large: 40pt Heavy（首页汇总）
- 尺寸 Medium: 22pt Semibold（列表汇总）
- 尺寸 Small: 16pt Semibold（列表行）
- 尺寸 Micro: 12pt Medium（徽章内）

**属性参数**:
```swift
struct AmountDisplay: View {
    let amount: Decimal
    let type: AmountType        // .income | .expense | .balance | .neutral
    let size: AmountSize        // .large | .medium | .small | .micro
    let showSign: Bool          // 是否显示 +/- 符号
    let currencyCode: String    // 默认 "CNY"，显示 ¥
}
```

**使用场景**: 首页月度汇总、账单列表金额列、统计页合计、快捷记账输入显示。

---

### 6.5 IconBadge — 图标徽章

**设计描述**: 用于账本封面、分类标识的图标容器，图标 + 彩色圆形/方形背景。

**视觉规范**:
- 形状变体: 圆形（Circle）| 圆角方形（RoundedSquare，圆角 `radiusSM`）
- 尺寸 XS: 24×24pt（背景），12pt 图标
- 尺寸 SM: 32×32pt，16pt 图标
- 尺寸 MD: 44×44pt（标准），22pt 图标
- 尺寸 LG: 60×60pt（账本封面），28pt 图标
- 背景色: 自定义颜色，默认 `appPrimarySurface`
- 图标色: 自定义颜色，默认 `appPrimary`
- 图标类型: SF Symbol 名称

**属性参数**:
```swift
struct IconBadge: View {
    let iconName: String          // SF Symbol
    let backgroundColor: Color
    let iconColor: Color
    let size: BadgeSize           // .xs | .sm | .md | .lg
    let shape: BadgeShape         // .circle | .roundedSquare
}
```

**使用场景**: 账本列表图标、分类选择网格图标、账单行类别标识。

---

### 6.6 SectionHeader — 分组标题

**设计描述**: 内容区域的分组标题栏，左侧标题 + 可选右侧操作按钮。

**视觉规范**:
- 标题: 16pt Semibold，`appTextPrimary`
- 右侧操作文字: 14pt Regular，`appPrimary`
- 左侧可选彩色装饰线（3×18pt 圆角矩形，颜色为主色）
- 上间距: `spacing6`（24pt），下间距: `spacing3`（12pt）
- 背景: 透明

**属性参数**:
```swift
struct SectionHeader: View {
    let title: String
    let subtitle: String?          // 可选副标题
    let actionTitle: String?       // 可选右侧操作文字
    let showAccentBar: Bool        // 是否显示左侧装饰线，默认 false
    let action: (() -> Void)?
}
```

**使用场景**: 首页"本月账单"、统计页"支出分类"、设置页分组标题。

---

### 6.7 EmptyStateView — 空状态视图

**设计描述**: 列表或内容区域无数据时的占位视图，图示 + 文案 + 可选操作按钮。

**视觉规范**:
- 插图: 80×80pt SF Symbol 或自定义插图，颜色 `appPlaceholder`
- 主文案: 18pt Semibold，`appTextSecondary`，居中
- 副文案: 14pt Regular，`appTextTertiary`，居中，最多 2 行
- 操作按钮: 可选 PrimaryButton（compact 尺寸）
- 整体垂直居中，距离父容器顶部 ≥ 80pt

**属性参数**:
```swift
struct EmptyStateView: View {
    let iconName: String           // SF Symbol，默认 "tray.fill"
    let title: String
    let subtitle: String?
    let actionTitle: String?
    let action: (() -> Void)?
}
```

**使用场景**: 账本列表为空、账单列表无结果、统计页无数据。

---

### 6.8 TagChip — 标签/分类选择器

**设计描述**: 胶囊形标签，用于分类选择、筛选条件、状态标注。

**视觉规范**:
- 默认态: `appBackgroundAlt` 背景，`appTextSecondary` 文字，无描边
- 选中态: `appPrimary` 背景，白色文字
- 高亮态: `appPrimarySurface` 背景，`appPrimary` 文字 + `appPrimary` 0.5pt 描边
- 高度: 32pt（标准），28pt（紧凑）
- 内边距: 水平 12pt，垂直 6pt
- 圆角: `radiusFull`
- 字号: 13pt Medium
- 可选前置图标: 14pt SF Symbol

**属性参数**:
```swift
struct TagChip: View {
    let title: String
    let iconName: String?
    let style: ChipStyle           // .default | .selected | .highlighted
    let size: ChipSize             // .standard | .compact
    let onTap: (() -> Void)?       // nil 则不可点击
}
```

**使用场景**: 账单分类选择横向滚动列表、统计筛选（周/月/年）、账单类型切换（收入/支出）。

---

### 6.9 LoadingIndicator — 加载指示器

**设计描述**: 数据加载、保存操作时的进度反馈。

**视觉规范**:
- 内联型: 16pt `ProgressView`，颜色 `appPrimary`，与文字同行
- 覆盖型: 白色圆角卡片（`radiusLG`，80×80pt）+ 32pt spinner + 说明文字，毛玻璃背景蒙层
- Spinner 颜色: `appPrimary`
- 出现/消失动画: fade，0.2s ease

**属性参数**:
```swift
struct LoadingIndicator: View {
    let style: LoadingStyle        // .inline | .overlay
    let message: String?           // 覆盖型时的提示文字
}
```

**使用场景**: 账单保存、数据导出、账本切换加载。

---

### 6.10 CustomNavBar — 自定义导航栏

**设计描述**: 替代系统 NavigationBar，提供统一的自定义样式。（已有实现，规范化参数）

**视觉规范**:
- 高度: 44pt（标准），56pt（大标题模式）
- 背景: 默认透明，滚动后变为 `appCard` + `shadowLight()`
- 标题: 17pt Semibold，`appTextPrimary`，居中
- 大标题: 28pt Bold，`appTextPrimary`，左对齐
- 左侧返回按钮: 24pt SF Symbol（`chevron.left`），颜色 `appPrimary`
- 右侧操作按钮: 最多 2 个，24pt SF Symbol，颜色 `appPrimary`
- 分隔线: 滚动前不显示，滚动后显示 0.5pt `appDivider` 细线
- Safe Area: 顶部 padding 自动适配 StatusBar 高度

**属性参数**:
```swift
struct CustomNavBar: View {
    let title: String
    let style: NavBarStyle         // .standard | .largeTitle
    let leftItem: NavBarItem?      // 返回按钮或自定义
    let rightItems: [NavBarItem]   // 最多 2 个
    let showDivider: Bool          // 由外部传入滚动偏移量控制
}
```

---

### 6.11 BottomTabBar — 底部标签栏

**设计描述**: 全局底部导航，包含 3 个主 Tab + 1 个悬浮记账按钮。（已有实现，规范化参数）

**视觉规范**:
- 背景: 白色（`appCard`），顶部 0.5pt `appDivider` 分隔线 + `shadowLight()`（向上）
- Tab 数量: 3 个（账单、统计、设置），中间预留 FAB 位置
- Tab 图标: 24pt SF Symbol，非激活色 `appTextTertiary`，激活色 `appPrimary`
- Tab 文字: 10pt Regular，非激活色 `appTextTertiary`，激活色 `appPrimary`
- 激活指示器: Tab 图标上方 2×16pt 圆角矩形，颜色 `appPrimary`，出现动画 spring
- FAB（浮动记账按钮）:
  - 尺寸: 56×56pt 圆形
  - 背景: 主色渐变
  - 图标: 28pt `plus`，白色
  - 阴影: `shadowEmphasis()`
  - 位置: 底部栏垂直居中，相对底部栏向上偏移 12pt
- Safe Area: 底部 padding 自动适配 Home Indicator 高度

---

### 6.12 SearchBar — 搜索栏

**设计描述**: 账单搜索输入栏，支持聚焦动画。

**视觉规范**:
- 背景: `appBackgroundAlt`（浅灰）
- 圆角: `radiusFull`
- 高度: 40pt
- 左侧图标: 16pt `magnifyingglass`，颜色 `appTextTertiary`
- 内边距: 水平 12pt
- 占位文字: "搜索账单..."，颜色 `appPlaceholder`，14pt Regular
- 右侧清除按钮: 有内容时出现，16pt `xmark.circle.fill`，颜色 `appTextTertiary`
- 聚焦动画: 背景描边从无到 `appPrimary` 1.5pt，0.2s ease
- 右侧"取消"按钮: 聚焦时从右侧滑入，点击后收起键盘并清空

---

### 6.13 DateRangePicker — 日期范围选择器

**设计描述**: 用于统计页的时间范围切换组件。

**视觉规范**:
- 外观: 胶囊形分段控制器（Segmented Control 风格）
- 整体背景: `appBackgroundAlt`，圆角 `radiusFull`
- 选中段: 白色背景滑块（带 `shadowLight()`），动画 spring 切换
- 文字: 14pt Medium，非选中 `appTextSecondary`，选中 `appTextPrimary`
- 选项: 周 / 月 / 年（固定3段）
- 高度: 36pt
- 切换动画: 白色滑块以 matchedGeometryEffect 流畅移动

---

## 7. 各页面 UI 规范

---

### 7.1 首页/账单列表页（BillListView）

**页面职责**: 展示当前账本的账单流水，提供搜索和筛选，展示当月收支汇总。

#### 布局结构

```
┌─────────────────────────────────┐
│ StatusBar                       │
├─────────────────────────────────┤
│ CustomNavBar                    │
│  左: 账本名称（H3）+ 切换图标   │
│  右: 搜索图标 + 更多（···）     │
├─────────────────────────────────┤
│ 月度汇总卡片（CardView）        │
│  账本名称（H4，textSecondary）  │
│  月份导航（< 2025年3月 >）      │
│  支出金额（Display，红色）      │
│  收入金额（Medium，绿色）       │
│  余额（Medium，主色）           │
├─────────────────────────────────┤
│ SearchBar（可折叠）             │
├─────────────────────────────────┤
│ 分类筛选标签（横向滚动）        │
│  TagChip × N（全部/餐饮/交通…）│
├─────────────────────────────────┤
│ 账单列表（LazyVStack）          │
│  SectionHeader：日期 + 当日小计 │
│  BillRow × N                   │
│    IconBadge（分类图标）        │
│    左: 备注（Body）+ 分类（Caption）│
│    右: AmountDisplay（Small）  │
│       时间（Caption，tertiary） │
├─────────────────────────────────┤
│ BottomTabBar + FAB              │
└─────────────────────────────────┘
```

#### 关键元素规范

**月度汇总卡片**:
- 背景: 渐变 `[#FFFBEB → #FEF3C7]`（浅琥珀色）
- 圆角: `radiusXL`（24pt）
- 内边距: 20pt
- 月份切换箭头: 24pt `chevron.left` / `chevron.right`，颜色 `appPrimary`
- 三列数据（支出/收入/余额）均匀分布，垂直分隔线 `appDivider`

**账单行（BillRow）**:
- 高度: 64pt
- IconBadge: MD 尺寸（44pt），圆角方形
- 左侧信息区: 垂直排列备注（14pt Semibold）+ 分类（12pt Regular，tertiary）
- 右侧金额区: AmountDisplay（Small）+ 时间（Caption）
- 分隔线: 左侧与 IconBadge 对齐缩进（不全宽），颜色 `appDivider`，0.5pt
- 滑动操作: 左滑显示"编辑"（蓝）+ "删除"（红），图标为 SF Symbol

**交互规范**:
- 点击月份左右箭头: 切换月份，账单列表刷新，月度汇总更新，动画 `.easeInOut(duration: 0.3)`
- 点击账单行: Push 到 BillEditorView
- 左滑删除: 先弹出确认 ActionSheet，确认后删除并有 undo toast（3s）
- 下拉刷新: 支持 `.refreshable`
- 账本切换: 点击导航栏账本名，从底部弹出账本选择 Sheet

---

### 7.2 账本列表页（LedgerListView）

**页面职责**: 管理所有账本，创建、编辑、归档、删除账本。

#### 布局结构

```
┌─────────────────────────────────┐
│ StatusBar                       │
├─────────────────────────────────┤
│ CustomNavBar（大标题模式）       │
│  标题: "我的账本"               │
│  右: 添加按钮（+）              │
├─────────────────────────────────┤
│ 账本网格/列表（切换视图）       │
│                                 │
│  活跃账本（SectionHeader）      │
│  ┌──────────┐ ┌──────────┐     │
│  │ IconBadge│ │ IconBadge│     │
│  │ 账本名称 │ │ 账本名称 │     │
│  │ X笔 ¥XX │ │ X笔 ¥XX │     │
│  └──────────┘ └──────────┘     │
│                                 │
│  已归档账本（SectionHeader）    │
│  （折叠，点击展开）             │
├─────────────────────────────────┤
│ BottomTabBar                    │
└─────────────────────────────────┘
```

#### 关键元素规范

**账本卡片（2列网格）**:
- 宽度: `(screenWidth - 16×2 - 12) / 2`
- 高度: 160pt
- 背景: `appCard`，圆角 `radiusLG`，`shadowLight()`
- 顶部区域: IconBadge LG（60pt）居中，自定义颜色
- 底部区域: 账本名称（16pt Semibold）+ 账单数量 + 净余额（AmountDisplay Small）
- 当前激活账本: 边框 2pt `appPrimary` + 右上角打钩徽章
- 长按: 触觉反馈 + 进入编辑模式（抖动动画 + 删除角标）

**已归档区域**:
- 默认折叠，SectionHeader 右侧显示数量徽章
- 展开/折叠动画: `.easeInOut(0.3)`

**交互规范**:
- 点击账本: 进入对应账本的 BillListView
- 点击 + 号: 弹出 CreateLedgerSheet
- 长按账本卡片: 弹出 ContextMenu（编辑/归档/删除）
- 删除确认: Destructive Alert

---

### 7.3 快捷记账页（AddRecordView）

**页面职责**: 快速新增一条账单记录，核心路径极简化。

#### 布局结构

```
┌─────────────────────────────────┐
│ CustomNavBar                    │
│  左: 关闭（×）                 │
│  中: "记一笔"                  │
│  右: 账本选择器                 │
├─────────────────────────────────┤
│ 类型切换（收入/支出）           │
│  TagChip 胶囊切换               │
├─────────────────────────────────┤
│ 金额输入区                      │
│  ¥ 48pt 大数字（金额展示）     │
│  光标闪烁动画                  │
│  小数点支持                    │
├─────────────────────────────────┤
│ 分类选择网格（4×N）             │
│  IconBadge（MD）+ 分类名        │
│  选中态: 主色边框 + 背景        │
├─────────────────────────────────┤
│ 备注输入框（可选）              │
│  占位: "添加备注..."           │
│  内联文本，不弹出单独页面      │
├─────────────────────────────────┤
│ 日期选择（紧凑行内选择器）      │
│  默认今天，点击可修改           │
├─────────────────────────────────┤
│ PrimaryButton "保存"            │
│ 底部 Safe Area 留白             │
└─────────────────────────────────┘
```

#### 关键元素规范

**金额输入区**:
- 使用虚拟数字键盘（系统 `.numberPad`）
- 金额文字: 48pt Bold Rounded，居中
- 下方淡色分类提示: "请选择分类" （12pt，`appPlaceholder`）
- 空金额时显示 "0"，颜色 `appPlaceholder`

**分类网格**:
- 4列等宽布局
- 每格: IconBadge MD + 分类名（12pt Regular）
- 选中态: 整格背景 `appPrimarySurface`，圆角 `radiusMD`，图标边框 `appPrimary`
- 可横向滚动（若分类超过 8 个）

**交互规范**:
- 页面以半高/全高 Sheet 方式呈现（`.presentationDetents([.medium, .large])`）
- 输入金额时禁止页面滚动（键盘不遮挡）
- 快速选中分类后金额区轻微 spring 动画（表示已绑定分类）
- 保存成功: Sheet 关闭 + 短暂绿色成功 Toast（HUD 样式，1.5s）
- 保存失败（未输入金额/未选分类）: 相应区域轻微 shake 动画 + 红色提示文字

---

### 7.4 账单详情/编辑页（BillEditorView）

**页面职责**: 查看单条账单详情，并支持编辑所有字段。

#### 布局结构

```
┌─────────────────────────────────┐
│ CustomNavBar                    │
│  左: 返回（< 账单列表）        │
│  右: 编辑/保存 切换按钮         │
├─────────────────────────────────┤
│ 账单概览卡片（大卡片）          │
│  分类图标（IconBadge LG）       │
│  金额（AmountDisplay Large）   │
│  分类名 + 日期                  │
├─────────────────────────────────┤
│ 详情字段区（CardView 卡片组）   │
│  备注行: 图标 + 内容/输入框    │
│  账本行: 图标 + 账本名称       │
│  日期行: 图标 + 日期选择器     │
│  标签行: 图标 + TagChip 列表   │
├─────────────────────────────────┤
│ （编辑模式）PrimaryButton 保存 │
│ 分类重新选择网格（编辑模式）    │
├─────────────────────────────────┤
│ 危险操作区（编辑模式）          │
│  删除账单（红色文字按钮）       │
└─────────────────────────────────┘
```

#### 交互规范

- 默认为**查看模式**，右上角"编辑"按钮切换到编辑模式
- 编辑模式: 字段变为可输入状态，右上角切换为"保存"，出现"取消"（左侧）
- 编辑模式切换动画: `.easeInOut(0.2)`，字段背景色过渡
- 删除操作: Destructive Confirmation Alert

---

### 7.5 统计分析页（StatisticsView）

**页面职责**: 展示指定时间段的收支统计，包含图表和分类明细。

#### 布局结构

```
┌─────────────────────────────────┐
│ CustomNavBar（大标题）          │
│  标题: "统计"                  │
│  右: 导出按钮                  │
├─────────────────────────────────┤
│ 时间范围选择（DateRangePicker）  │
│  周 / 月 / 年                   │
├─────────────────────────────────┤
│ 时间导航（< 2025年3月 >）       │
├─────────────────────────────────┤
│ 收支汇总卡片                    │
│  支出（大） / 收入（大）        │
│  余额（中）                    │
├─────────────────────────────────┤
│ 趋势折线图（CardView）          │
│  折线颜色: expense(红)/income(绿)│
│  X轴: 日期，Y轴: 金额          │
│  交互: 点击显示 tooltip         │
├─────────────────────────────────┤
│ 支出分类饼图（CardView）        │
│  环形饼图（中心显示总额）       │
│  右侧分类图例列表               │
├─────────────────────────────────┤
│ 分类排行（CardView）            │
│  SectionHeader "支出明细"       │
│  分类进度条 × N                 │
│   IconBadge + 分类名 + 进度条 + 金额│
├─────────────────────────────────┤
│ BottomTabBar                    │
└─────────────────────────────────┘
```

#### 关键元素规范

**趋势折线图**:
- 使用 Swift Charts
- 折线宽度: 2pt
- 渐变填充区域: 线下方淡色渐变（对应颜色，透明度 0.1~0）
- 数据点: 6pt 圆形，按下高亮
- 网格线: `appDivider`，水平虚线

**环形饼图**:
- 外圆直径: 160pt
- 环宽: 28pt
- 中心: 总金额（AmountDisplay Medium）
- 颜色: 系统自动分配（12色预设暖色调色板）
- 选中段: 向外弹出 6pt，spring 动画

**分类进度条**:
- 高度: 6pt，圆角 `radiusFull`
- 进度色: 对应分类颜色
- 背景色: `appBackgroundAlt`

---

### 7.6 设置页（SettingsView）

**页面职责**: 应用偏好设置、账户信息、帮助与反馈。

#### 布局结构

```
┌─────────────────────────────────┐
│ CustomNavBar（大标题）          │
│  标题: "设置"                  │
├─────────────────────────────────┤
│ 用户信息卡片（CardView）        │
│  头像（60pt 圆形）+ 用户名      │
│  副标题（账本数量统计）         │
├─────────────────────────────────┤
│ 通用设置（CardView 分组）       │
│  货币设置（行）                 │
│  默认账本（行）                 │
│  每周开始日（行）               │
├─────────────────────────────────┤
│ 数据管理（CardView 分组）       │
│  导出数据（行）                 │
│  备份与恢复（行）               │
├─────────────────────────────────┤
│ 关于（CardView 分组）           │
│  版本号（行，灰色）             │
│  隐私政策（行）                 │
│  联系反馈（行）                 │
├─────────────────────────────────┤
│ BottomTabBar                    │
└─────────────────────────────────┘
```

#### 关键元素规范

**设置行（SettingsRow）**:
- 高度: 52pt
- 左侧: IconBadge SM（32pt）彩色图标 + 标题（Body）
- 右侧: 值文字（Body Sm，`appTextSecondary`）+ `chevron.right`（可选）
- 分隔线: 仅 CardView 内部，左侧与图标对齐缩进
- Toggle 类型: 使用系统 Toggle，tint 颜色 `appPrimary`

**CardView 分组**:
- 每个分组使用独立 CardView，内部行之间有细分隔线
- 分组之间间距: `spacing5`（20pt）

---

## 8. 交互动效规范

### 8.1 页面转场动画

| 场景 | 动画类型 | 时长 | 曲线 |
|------|---------|------|------|
| Push（进入子页面） | 标准右滑 Push（系统默认） | 350ms | `easeInOut` |
| Pop（返回） | 标准左滑 Pop（系统默认） | 350ms | `easeInOut` |
| Sheet 弹出 | 从底部滑入（系统 Sheet） | 400ms | Spring（damping: 0.85） |
| Sheet 收起 | 向下滑出 | 300ms | `easeIn` |
| Tab 切换 | Crossfade 淡入淡出 | 200ms | `easeInOut` |
| 账本切换 | 横向滑动（Left/Right） | 250ms | `easeInOut` |

### 8.2 按钮点击反馈

```swift
// 所有可点击元素的按压效果
.buttonStyle(.plain)
.scaleEffect(isPressed ? 0.97 : 1.0)
.animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)

// 触觉反馈
// 轻量操作（分类选择、Tab 切换）: .light
// 标准操作（保存、确认）: .medium
// 危险操作（删除）: .heavy + 警告音
let generator = UIImpactFeedbackGenerator(style: .medium)
generator.impactOccurred()
```

### 8.3 数据加载过渡

- **骨架屏（Skeleton Loading）**: 首次加载时，内容区域显示灰色渐变占位块（shimmer 动画，1.5s 循环）
- **渐入显示**: 数据就绪后，内容以 `opacity 0→1` + `offset y:12→0` 过渡出现，时长 300ms
- **局部刷新**: 数字变化时使用 `.contentTransition(.numericText())` 或自定义数字翻滚动画

### 8.4 删除/归档手势

**列表行左滑**:
```
← 滑动 60pt: 显示操作按钮区域（编辑/删除）
  - 编辑按钮: 蓝色背景，白色 pencil 图标
  - 删除按钮: 红色背景，白色 trash 图标
← 滑动 > 80%: 触发直接删除（Full Swipe），伴随触觉反馈
```

**删除确认 Alert**:
```
标题: "删除账单"
内容: "确认删除「{备注}」？此操作不可撤销。"
操作: [取消（Default）] [删除（Destructive）]
```

**归档手势**: 长按账本卡片 → ContextMenu → 归档（动画: 卡片向下淡出，移入归档区）

### 8.5 特殊动效

**金额输入数字滚动**:
- 数字变化时，新数字从下方滑入，旧数字向上滑出，单个字符独立动画

**FAB 按钮脉冲**:
- 首次启动 App 时，FAB 有一次轻微的脉冲动画（scale 1.0→1.1→1.0，2s delay）

**分类选中波纹**:
- 点击分类图标时，背景以圆形波纹扩散方式显示选中（类似涟漪效果，0.3s）

---

## 9. iOS 适配规范

### 9.1 Safe Area 处理

```swift
// 页面根容器必须处理 Safe Area
VStack(spacing: 0) {
    CustomNavBar(...)
    ScrollView {
        content
            .padding(.bottom, 16) // 内容底部留白
    }
    // BottomTabBar 不在 ScrollView 内
}
.ignoresSafeArea(edges: .top) // 允许 NavBar 延伸到状态栏区域

// BottomTabBar 处理
VStack {
    tabContent
    BottomTabBar()
        .padding(.bottom, safeAreaInsets.bottom) // 适配 Home Indicator
}
.ignoresSafeArea(edges: .bottom)
```

**Safe Area 规则**:
- 顶部: CustomNavBar 背景延伸到 StatusBar，StatusBar 文字颜色统一为深色
- 底部: BottomTabBar 高度 = 49pt（内容区）+ `safeAreaInsets.bottom`（通常 34pt on iPhone 14+）
- 左右: 内容区左右边距 16pt（基于 Safe Area 内侧）

### 9.2 Dark Mode 支持策略

**当前版本**: 专注 Light Mode，Dark Mode 暂不支持。

```swift
// 在 App 入口处强制 Light Mode
WindowGroup {
    ContentView()
        .preferredColorScheme(.light)
}
```

**未来 Dark Mode 规划**（v2.0）:
- 所有颜色从硬编码 HEX 迁移到 `Color.primary`（系统自适应色）或 Asset Catalog 中定义 Light/Dark 双值
- 背景系统: Light 使用 stone-50，Dark 使用 `#1C1917`（stone-900）
- 卡片背景: Light 白色，Dark `#292524`（stone-800）

### 9.3 动态字体（Dynamic Type）支持

**基本策略**: 支持用户辅助功能字体大小调整，但设置上限以保护布局。

```swift
// 标准文字使用系统字体，自动支持 Dynamic Type
Text("标题")
    .font(.headline) // 自动跟随系统字体大小

// 金额数字限制最大缩放（防止布局破坏）
Text(amountText)
    .font(.system(size: 40, weight: .heavy, design: .rounded))
    .minimumScaleFactor(0.7)   // 允许最小缩放至 70%
    .lineLimit(1)

// 自定义字号场景
Text(label)
    .font(.system(size: 14))
    .dynamicTypeSize(.xSmall ... .xxxLarge) // 限制动态字体范围
```

**布局注意**:
- 所有行高使用相对值（`.lineLimit()` + `minimumScaleFactor`），避免固定高度裁切文字
- 分类网格在超大字体时退化为 3 列（默认 4 列）
- 金额展示组件在超大字体时自动缩小字号，保持单行显示

### 9.4 设备适配

| 设备 | 屏幕宽度 | 适配策略 |
|------|---------|---------|
| iPhone SE（3rd） | 375pt | 默认基准，所有组件以此为最小参考 |
| iPhone 14 | 390pt | 标准设计稿尺寸 |
| iPhone 14 Plus / Pro Max | 428pt | 账本网格每行可显示 2~3 列 |
| iPad（未来扩展） | ≥768pt | 使用 SplitView，侧边导航 |

```swift
// 网格列数自适应
let columns = UIScreen.main.bounds.width > 400 ? 3 : 2
let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: columns)
```

---

## 附录

### A. 色彩速查表

| 用途 | HEX | 使用位置 |
|------|-----|---------|
| 主色 | `#F59E0B` | 按钮、激活状态、品牌元素 |
| 主色浅 | `#FCD34D` | 渐变高亮端 |
| 主色深 | `#D97706` | 渐变深色端 |
| 收入 | `#10B981` | 收入金额、收入标识 |
| 支出 | `#F43F5E` | 支出金额、支出标识 |
| 主背景 | `#FAFAF9` | 页面全局背景 |
| 卡片 | `#FFFFFF` | 所有卡片背景 |
| 主文字 | `#1C1917` | 标题、正文 |
| 次要文字 | `#78716C` | 副标题、标签 |
| 辅助文字 | `#A8A29E` | 时间、说明 |

### B. 组件引用速查

| 组件名 | 主要使用页面 |
|--------|-----------|
| `PrimaryButton` | AddRecordView, BillEditorView, LedgerListView |
| `CardView` | 全部页面 |
| `AmountDisplay` | BillListView, StatisticsView, AddRecordView |
| `IconBadge` | BillListView, AddRecordView, LedgerListView, StatisticsView |
| `TagChip` | BillListView（筛选）, AddRecordView（类型切换）, StatisticsView（时间范围）|
| `SectionHeader` | BillListView, StatisticsView, SettingsView |
| `EmptyStateView` | BillListView, LedgerListView, StatisticsView |
| `SearchBar` | BillListView |
| `DateRangePicker` | StatisticsView |
| `CustomNavBar` | 全部页面 |
| `BottomTabBar` | BillListView, LedgerListView, StatisticsView, SettingsView |

---

*文档结束 — BillManager UI 设计规范 v1.0*
