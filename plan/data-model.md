# 数据模型设计

## Prompt 模型

核心实体，每条 prompt 代表一个待执行的 Claude Code 任务。

```dart
class Prompt {
  final String id;          // UUID
  final String content;     // prompt 文本内容
  final String branch;      // 目标 git branch 名称
  final int priority;       // 优先级（数字越小越先执行）
  final PromptStatus status; // 执行状态
  final bool isSkipped;     // 是否跳过
  final DateTime createdAt;
  final DateTime updatedAt;
}

enum PromptStatus {
  pending,   // 待执行
  running,   // 执行中
  done,      // 已完成
  failed,    // 执行失败
}
```

## Branch 模型（派生，不存储）

Branch 不单独存储，而是从 Prompt 数据中动态聚合。

```dart
class BranchSummary {
  final String name;           // branch 名称
  final int totalCount;        // 总 prompt 数
  final int pendingCount;      // 待执行数
  final int doneCount;         // 已完成数
  final int skippedCount;      // 已跳过数
  final List<Prompt> prompts;  // 关联的 prompt 列表
}
```

## 执行会话模型（内存，不持久化）

```dart
class ExecutionSession {
  final String id;
  ExecutionStatus status;    // idle / running / paused
  String? currentPromptId;   // 当前正在执行的 prompt
  int completedCount;
  int totalCount;
  final DateTime startedAt;
}

enum ExecutionStatus { idle, running, paused }
```

## 数据库 Schema（Drift）

```sql
CREATE TABLE prompts (
  id         TEXT PRIMARY KEY,
  content    TEXT NOT NULL,
  branch     TEXT NOT NULL,
  priority   INTEGER NOT NULL DEFAULT 0,
  status     TEXT NOT NULL DEFAULT 'pending',
  is_skipped INTEGER NOT NULL DEFAULT 0,  -- 0/1 bool
  created_at INTEGER NOT NULL,            -- Unix timestamp ms
  updated_at INTEGER NOT NULL
);

CREATE INDEX idx_prompts_branch    ON prompts(branch);
CREATE INDEX idx_prompts_priority  ON prompts(priority);
CREATE INDEX idx_prompts_status    ON prompts(status);
```

## Priority 规则

- priority 值越小 → 越先执行（升序排列）
- 同 branch 内的 prompt 共享 priority 空间
- 新增 prompt 默认 priority = 当前最大值 + 10（留出调整空间）
- 调整优先级时，只需交换两条记录的 priority 值

## 状态转换图

```
pending ──[执行]──→ running ──[成功]──→ done
   │                  │
   │              [失败]──→ failed
   │
   └──[标记跳过]──→ (isSkipped = true, status 不变)

done / failed ──[重置]──→ pending
```
