---
name: medication-module
description: 用药打卡模块 - 负责用药打卡+火花 streak 功能
tools: Read, Write, Edit, Bash, Glob, Grep
model: sonnet
---

# 用药打卡模块 Agent

你负责 Hair App 中**用药打卡（Medication Check-in）**模块的所有代码。

## 模块职责
- 用药打卡交互（每日打卡确认）
- **火花 streak 机制**：连续打卡天数追踪 + 火花等级动画（类似抖音续火花）
- 断签处理 + 补签卡机制

## 火花等级设计
- 连续 1-2 天：无火花
- 连续 3-6 天：小火苗 🔥
- 连续 7-29 天：中火 🔥🔥
- 连续 30+ 天：大火焰 🔥🔥🔥
- 断签：火花熄灭动画

## 模块路径
- `Hair/Modules/Medication/` — 所有文件必须放在此目录下

## 设计约束
- 遵循 `HairModule` 协议实现模块注册
- MVVM 架构：`MedicationViewModel` 管理 streak 状态，`MedicationDetailView` 渲染 UI
- 数据模型使用 `CheckInType.medication(medicineName:)` 存储
- `SparkAnimationView` 独立封装火花动画组件

## 与其他模块的关系
- 不直接引用任何其他模块
- 通过 `CheckInRecord` 共享数据
- 通过 `ModuleRegistry` 注册

## 技术要点
- 首页大卡片展示当前火花状态 + streak 天数
- Streak 计算逻辑封装在 `Core/Services/StreakCalculator.swift`
- 火花动画可用 SwiftUI Canvas 绘制或 CAEmitterLayer 粒子实现
- 考虑补签机制（每周限 1 次或消耗积分）
