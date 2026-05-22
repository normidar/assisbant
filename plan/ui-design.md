# UI 结构与导航设计

## 导航结构

```
App
├── BottomNavigationBar / NavigationRail
│   ├── [0] Prompts Tab（Prompt 列表）
│   ├── [1] Branches Tab（Branch 视图）
│   └── [2] Settings Tab（配置）
│
├── Prompts Tab
│   ├── PromptListPage
│   │   ├── FilterChips（全部/待执行/已完成/已跳过）
│   │   ├── PromptCard × N
│   │   └── FAB → 新建
│   └── PromptEditPage（新建/编辑）
│
├── Branches Tab
│   ├── BranchListPage
│   │   └── BranchCard × N（名称 + 进度统计）
│   └── BranchDetailPage
│       ├── FilterChips（全部/待执行/已完成）
│       └── ReorderablePromptList
│
└── Settings Tab
    ├── Claude CLI 路径
    └── 工作目录
```

## 执行控制栏

固定显示在底部（在 BottomNavigationBar 之上）：

```
┌─────────────────────────────────────────────┐
│  [▶ 开始] / [⏸ 暂停]   进度: 3/12   [当前: branch-name] │
└─────────────────────────────────────────────┘
```

- 空闲时：显示 "▶ 开始执行" 按钮
- 执行中：显示 "⏸ 暂停" + 实时进度
- 暂停中：显示 "▶ 继续" + 进度

## PromptCard 设计

```
┌─────────────────────────────────────────┐
│ #3  [main]                    ● pending │
│ 实现用户登录页面，使用 Email + OAuth...   │
│                              [编辑] [跳过]│
└─────────────────────────────────────────┘
```

- `#3`：priority 编号
- `[main]`：branch 标签（彩色 chip）
- `● pending`：状态 badge（颜色区分）
  - pending → 蓝色
  - running → 橙色（动画）
  - done → 绿色
  - failed → 红色
  - skipped → 灰色（透明度降低）

## BranchCard 设计

```
┌─────────────────────────────────────────┐
│ feature/auth                            │
│ ████░░░░  3 / 8 已完成                  │
└─────────────────────────────────────────┘
```

## PromptEditPage 字段

```
内容（多行文本输入）
─────────────────────────────────
Branch（下拉选择 + 新建输入）
  [main] [feature/auth] [+ 新建]

Priority（数字输入）
  [  10  ]  ← → 调整

□ 跳过此 Prompt

        [取消]  [保存]
```

## 响应式布局

- 手机：BottomNavigationBar + 单栏
- 平板/桌面：NavigationRail + 双栏（列表 + 详情）

利用已有的 `colaxy_adaptive_scaffold` 包实现自适应布局。
