# 系统架构设计

## 整体架构

```
┌──────────────────────────────────────────────────────────┐
│                        Flutter App                       │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │  AppShell (app_shell.dart)                         │  │
│  │  · Desktop: Sidebar + content area                 │  │
│  │  · Mobile:  NavigationBar + compact exec bar       │  │
│  │                                                    │  │
│  │  ┌────────────┐ ┌─────────────┐ ┌───────────────┐ │  │
│  │  │ Prompts    │ │ Branches    │ │ Logs /Settings│ │  │
│  │  │ Screen     │ │ Screen      │ │ Screen        │ │  │
│  │  └─────┬──────┘ └──────┬──────┘ └───────┬───────┘ │  │
│  │        │               │                │          │  │
│  │  ┌─────▼───────────────▼────────────────▼───────┐ │  │
│  │  │            Riverpod State Layer               │ │  │
│  │  │  PromptListNotifier · ExecNotifier            │ │  │
│  │  │  UI providers (tab / filter / search / lang)  │ │  │
│  │  └──────────────────────┬────────────────────────┘ │  │
│  │                         │                           │  │
│  │  ┌──────────────────────▼────────────────────────┐ │  │
│  │  │              Repository / Service Layer        │ │  │
│  │  │  PromptRepository · ExecutionService           │ │  │
│  │  └─────────────┬───────────────────┬─────────────┘ │  │
│  └────────────────┼───────────────────┼───────────────┘  │
└───────────────────┼───────────────────┼──────────────────┘
                    │                   │
        ┌───────────▼───────┐  ┌────────▼──────────┐
        │  本地数据库        │  │  Claude Code CLI   │
        │  Drift / SQLite   │  │  dart:io Process   │
        └───────────────────┘  └───────────────────┘
```

## 分层说明

### UI 层
| 文件 | 职责 |
|------|------|
| `app/app_shell.dart` | 根布局，响应式切换 desktop sidebar / mobile nav，挂载 `ExecBar` |
| `screens/prompts/prompts_screen.dart` | Prompt 列表、搜索、过滤、详情面板 |
| `screens/branches/branches_screen.dart` | Branch 卡片网格，点击跳转至 Prompt 列表并过滤 |
| `screens/logs/logs_screen.dart` | 执行日志查看器，左侧列表 + 右侧终端风格 log 窗口 |
| `screens/settings/settings_screen.dart` | CLI 路径、工作目录、行为开关 |
| `widgets/exec_bar.dart` | 固定在底部的执行控制栏（开始 / 暂停 / 继续 / 停止 + 进度条）|

### State 层 (Riverpod)

**数据类 providers（`state/prompt_notifier.dart`）**
- `PromptListNotifier`：AsyncNotifier，封装所有 Prompt CRUD + swapPriority + toggleSkip

**执行 provider（`state/exec_notifier.dart`）**
- `ExecNotifier`：Notifier，管理 `ExecState`（idle / running / paused），驱动真实执行循环
- 执行循环使用 `Completer<void>` 实现 pause/resume，`_stopRequested` flag 实现 stop

**UI 状态 providers（`state/ui_providers.dart`）**

| Provider | 类型 | 职责 |
|----------|------|------|
| `currentTabProvider` | `AppTab` | 当前激活的导航 Tab |
| `langNotifierProvider` | `String` | 界面语言（en / zh） |
| `filterNotifierProvider` | `String` | Prompt 列表过滤（all / pending / done …）|
| `searchQueryProvider` | `String` | 搜索关键词 |
| `selectedPromptIdProvider` | `String?` | 右侧详情面板选中的 Prompt |
| `branchFilterProvider` | `String?` | 按 branch 过滤 Prompt 列表 |
| `settingsStateProvider` | `AppSettings` | CLI 路径、工作目录、autoCheckout、pauseOnFail |

### Repository / Service 层

**`PromptRepository`（`data/repositories/prompt_repository.dart`）**
- 封装所有 Drift 数据库操作
- 提供 `getAll()` / `getByBranch()` / `getExecutable()` / `getBranchSummaries()`
- 提供 `insert()` / `update()` / `updateStatus()` / `updateOutput()` / `updatePriority()` / `delete()`
- 提供 `watchAll()` / `watchByBranch()` Stream

**`ExecutionService`（`data/services/execution_service.dart`）**
- 封装 `dart:io Process.run` 调用 `claude --print "<content>"`
- `autoCheckout = true` 时先 `git checkout <branch>`
- 返回 `ExecutionResult { success, output, error? }`
- 展开 `~` 路径，支持自定义 CLI 路径

### 数据层

**本地数据库 — Drift (SQLite)**
- 数据库文件：`assisbant_db`（`app_database.dart`）
- Schema version 2（v1 → v2 migration：添加 `output` 列）
- Providers：`appDatabaseProvider`、`promptRepositoryProvider`、`executionServiceProvider`

**Claude Code CLI**
- 通过 `ExecutionService.run()` 调用
- 命令：`claude --print "<prompt content>"`，在 `settings.workdir` 目录下执行

## 数据模型

### Prompts 表（SQLite）

```sql
CREATE TABLE prompts (
  id         TEXT PRIMARY KEY,      -- UUID v4
  content    TEXT NOT NULL,
  branch     TEXT NOT NULL,
  priority   INTEGER NOT NULL DEFAULT 0,
  status     TEXT NOT NULL DEFAULT 'pending',  -- pending/running/done/failed
  is_skipped INTEGER NOT NULL DEFAULT 0,
  output     TEXT,                  -- Claude Code 执行输出（nullable，v2 新增）
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
```

### BranchSummary（派生，不持久化）

从 `PromptRepository.getBranchSummaries()` 按 branch 聚合得出，包含 `pendingCount / doneCount / failedCount / skippedCount`。

### AppSettings（内存，不持久化）

`cliPath / workdir / autoCheckout / pauseOnFail`，存在 `settingsStateProvider` 中。

## 关键数据流

### 创建并执行 Prompt

```
用户输入 → PromptListNotifier.add() → PromptRepository.insert()
→ 用户点击"开始执行" → executableQueue(prompts) 按 priority 排序
→ ExecNotifier.start(queue)
→ _runLoop() 逐条迭代：
    1. repo.updateStatus(running)  → invalidate PromptListNotifier
    2. ExecutionService.run(prompt, settings)
       ├─ git checkout <branch>（若 autoCheckout）
       └─ claude --print "<content>"（在 workdir 执行）
    3. repo.updateStatus(done/failed)
    4. repo.updateOutput(stdout/stderr)  → invalidate PromptListNotifier
    5. 若失败 && pauseOnFail → 等待 Completer
```

### Pause / Resume / Stop

```
pause()  → _pauseCompleter = Completer()，status = paused
           _runLoop 在 i+1 开始前检测到 paused 状态，await completer
resume() → status = running，completer.complete()
stop()   → _stopRequested = true，completer.complete()，state 重置
```

### Branch 视图派生

```
PromptRepository.getBranchSummaries()
→ getAll() → group by branch
→ List<BranchSummary> { name, prompts[], pendingCount, doneCount … }
→ BranchesScreen 渲染卡片网格
```

## 响应式布局

- `width > 720` → Desktop：240px 固定 Sidebar + NavigationRail + 内容区 + 底部 ExecBar
- `width ≤ 720` → Mobile：全屏内容 + 底部紧凑执行栏 + NavigationBar
- Sidebar 含 branch 快捷链接（点击自动切到 PromptsScreen 并设置 branchFilter）

## 目录结构

```
lib/
├── main.dart
└── src/
    ├── app/
    │   ├── app_shell.dart       # 根布局 + 导航
    │   └── theme.dart           # AppColors + ThemeData
    ├── data/
    │   ├── database/
    │   │   ├── app_database.dart  # Drift schema (v2)
    │   │   └── prompt_status.dart # PromptStatus enum
    │   ├── models/
    │   │   └── branch_summary.dart
    │   ├── repositories/
    │   │   └── prompt_repository.dart
    │   └── services/
    │       └── execution_service.dart   # Claude CLI 集成
    ├── i18n/
    │   └── app_strings.dart     # EN / ZH 字符串
    ├── providers/
    │   └── database_providers.dart  # DB / repo / svc providers
    ├── screens/
    │   ├── branches/branches_screen.dart
    │   ├── logs/logs_screen.dart
    │   ├── prompts/
    │   │   ├── prompt_card.dart
    │   │   ├── prompt_edit_modal.dart
    │   │   └── prompts_screen.dart
    │   └── settings/settings_screen.dart
    ├── state/
    │   ├── exec_notifier.dart   # 执行引擎 + ExecState
    │   ├── prompt_notifier.dart # PromptListNotifier
    │   └── ui_providers.dart    # Tab / filter / search / settings
    └── widgets/
        ├── branch_chip.dart
        ├── exec_bar.dart
        └── status_badge.dart
```
