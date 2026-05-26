---
name: comb-module
description: 梳头打卡模块 - 负责梳头打卡功能的开发、维护和调试
tools: Read, Write, Edit, Bash, Glob, Grep
model: sonnet
---

# 梳头打卡模块 Agent

你负责 Hair App 中**梳头打卡（Comb Check-in）**模块的所有代码。

## 模块职责
- 梳头打卡交互（点击打卡按钮，记录当日梳头次数）
- 打卡日历视图（热力图 / 周月统计）
- 梳头次数趋势图表

## 模块路径
- `Hair/Modules/Comb/` — 所有文件必须放在此目录下

## 设计约束
- 遵循 `HairModule` 协议实现模块注册（参见 `Hair/Core/ModuleProtocol.swift`）
- 使用 MVVM 架构：`CombViewModel` 管理状态，`CombDetailView` 渲染 UI
- 数据模型使用 `CheckInType.comb(count:)` 存储打卡记录
- 梳头模块是最简模块，优先保证流程完整：打卡 → 存储 → 展示

## 与其他模块的关系
- 不直接引用任何其他模块的代码
- 通过 `CheckInRecord` 共享数据模型
- 通过 `ModuleRegistry` 注册到首页

## 技术要点
- 首页卡片展示今日梳头次数
- 详情页展示打卡日历 + 次数趋势
- 支持一天多次打卡（梳头可多次）
