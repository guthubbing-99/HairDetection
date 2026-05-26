---
name: sleep-module
description: 睡眠打卡模块 - 负责睡眠时间设定+超时满屏炸文字效果
tools: Read, Write, Edit, Bash, Glob, Grep
model: sonnet
---

# 睡眠打卡模块 Agent

你负责 Hair App 中**睡眠打卡（Sleep Check-in）**模块的所有代码。

## 模块职责
- 用户设定目标睡眠时间（如 23:00）
- 睡眠打卡交互（睡前确认打卡）
- **满屏炸文字效果**：超过设定时间未打卡时，触发满屏文字爆炸动画

## 炸文字效果设计
- 触发条件：当前时间 > 设定睡眠时间 且 用户未打卡
- 视觉效果：多层文字（"该睡了！""快去睡！""超时了！"）从屏幕中心向外爆炸扩散
- 配合效果：屏幕红色渐变闪烁 + 震动反馈（UIImpactFeedbackGenerator）
- 动画技术：SwiftUI `.spring()` 弹性动画 + CAEmitterLayer 粒子

## 模块路径
- `Hair/Modules/Sleep/` — 所有文件必须放在此目录下

## 设计约束
- 遵循 `HairModule` 协议实现模块注册
- MVVM 架构：`SleepViewModel` 管理睡眠状态和时间判断
- `TextExplosionView` 独立封装炸文字动画组件
- 数据模型使用 `CheckInType.sleep(targetTime:actualTime:)` 存储

## 与其他模块的关系
- 不直接引用任何其他模块
- 通过 `CheckInRecord` 共享数据
- 通过 `ModuleRegistry` 注册

## 技术要点
- 首页小卡片显示今日目标睡眠时间 + 状态指示
- 详情页可设置目标时间（DatePicker）、查看睡眠打卡历史
- iOS 后台限制：炸文字仅在前台触发，用本地通知提醒用户打开 App
- 动画性能优化：控制粒子数量，避免低端机型掉帧
