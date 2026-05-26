# Hair - 头发养护 iOS App

## 设计理念

### 1. 模块化优先（Modularity First）
每个功能模块（梳头、用药、睡眠、食谱等）都是独立单元，通过 `HairModule` 协议挂载到主框架。模块之间互不引用，完全解耦。添加新模块不改老代码。

**实现方式：**
- 所有模块遵循统一的 `HairModule` 协议（id、displayName、icon、tintColor、makeHomeCard、makeDetailView）
- 通过 `ModuleRegistry` 集中注册和管理模块
- 文件结构按 `Modules/<模块名>/` 组织，每个模块内聚自己的 View、ViewModel、Model

### 2. 协议驱动（Protocol-Oriented）
面向协议编程，依赖抽象而非具体实现。模块只需满足协议契约即可接入，框架不关心模块内部实现细节。

### 3. 数据模型可扩展（Extensible Data Model）
打卡类型使用 `enum` + `associated value` 设计，新增打卡类型只需增加一个 case，不影响已有逻辑和存储。

### 4. 仪表盘式首页（Dashboard Home）
不使用 TabBar 堆砌底部标签（最多 5 个即满），采用类似 Apple 健康 App 的单页仪表盘 + 卡片布局：
- 核心粘性模块（用药火花）用大卡片突出展示
- 高频操作模块（梳头、睡眠）用双列小卡片
- 新增模块直接追加卡片到列表，带 NEW 标签，不影响现有布局

### 5. 渐进式复杂度（Progressive Complexity）
先跑通最简单的模块（梳头打卡），验证打卡→存储→展示全流程，再逐步叠加 streak 逻辑、粒子动画等复杂功能。

### 6. 体验优先（Experience First）
- 火花机制增强粘性（连续天数可视化）
- 超时满屏炸文字 + 震动反馈强化紧迫感
- 本地通知作为辅助提醒，核心交互在 app 前台完成

## 技术栈

- **UI**: SwiftUI
- **数据持久化**: SwiftData（iOS 17+）
- **通知**: UserNotifications
- **架构**: MVVM + Module Protocol
- **动画**: SwiftUI Animation + CAEmitterLayer（粒子）

## 项目结构

```
Hair/
├── App/HairApp.swift
├── Core/（协议、注册中心、通用模型、服务）
├── Modules/（按功能模块分文件夹）
├── Home/（首页仪表盘 + 卡片组件）
└── Assets/
```

## Subagent 架构

每个模块和核心层都有专属 subagent，定义在 `.claude/agents/` 下。开发时根据任务类型调用对应 agent：

| Agent | 职责 | 文件 |
|-------|------|------|
| `hair-core` | 协议定义、注册中心、数据模型、公共服务 | `.claude/agents/hair-core.md` |
| `home-module` | 首页仪表盘、卡片布局、导航路由 | `.claude/agents/home-module.md` |
| `comb-module` | 梳头打卡：打卡交互、日历、趋势 | `.claude/agents/comb-module.md` |
| `medication-module` | 用药打卡：火花 streak、断签补签 | `.claude/agents/medication-module.md` |
| `sleep-module` | 睡眠打卡：目标时间、满屏炸文字 | `.claude/agents/sleep-module.md` |

**使用原则：**
- 修改 Core 层时调用 `hair-core` agent
- 开发具体模块时调用对应模块 agent
- 修改首页布局时调用 `home-module` agent
- 跨模块改动先咨询 `hair-core` 确保协议兼容，再分配各模块 agent 并行执行
