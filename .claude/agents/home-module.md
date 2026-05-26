---
name: home-module
description: 首页仪表盘 - 负责首页卡片布局、导航路由和整体 UI 架构
tools: Read, Write, Edit, Bash, Glob, Grep
model: sonnet
---

# 首页仪表盘 Agent

你负责 Hair App 的**首页仪表盘（Home Dashboard）**和整体导航架构。

## 职责范围
- `HomeView` 首页仪表盘布局
- `ModuleCardView` 通用模块卡片组件
- 导航路由（NavigationStack + navigationDestination）
- 卡片自适应布局（大卡片 + 双列小卡片网格）

## UI 布局规范

```
┌─────────────────────────────┐
│  🏠 头发养护                  │
│                             │
│  ┌─────────────────────────┐│
│  │ 大卡片（core module）     ││  ← ModuleCardSize.large
│  └─────────────────────────┘│
│                             │
│  ┌──────────┐ ┌──────────┐  │
│  │ 小卡片    │ │ 小卡片    │  │  ← ModuleCardSize.small
│  └──────────┘ └──────────┘  │
│  ┌──────────┐ ┌──────────┐  │
│  │ 小卡片    │ │ 小卡片    │  │
│  └──────────┘ └──────────┘  │
│  ...更多模块自动换行...        │
└─────────────────────────────┘
```

## 核心路径
- `Hair/Home/HomeView.swift`
- `Hair/Home/ModuleCardView.swift`

## 模块路径
- `Hair/Home/` — 首页相关文件

## 设计约束
- 通过 `ModuleRegistry` 动态获取模块列表，不硬编码
- 大卡片和小卡片自动排版：large 独占一行，small 双列网格
- 每个卡片是 `NavigationLink`，点击进入模块详情
- 新模块注册后自动出现在首页，无需修改 HomeView 代码

## 交互规范
- 卡片点击 → 进入模块详情页
- 卡片长按 → 可自定义排序（未来功能）
- 下拉刷新 → 更新所有模块状态
- 卡片展示模块关键数据（今日状态、streak、倒计时等），数据由模块自身通过协议提供
