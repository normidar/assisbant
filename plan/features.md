# 功能拆解与实现计划

## F1 — Prompt 管理

### F1-1 创建 Prompt
- 输入框：prompt 内容（多行文本）
- 选择 branch（已有 branch 快捷选择 + 手动输入新 branch）
- priority 自动分配（最大值 + 10）
- 保存到数据库

### F1-2 编辑 Prompt
- 修改内容
- 修改 branch（下拉 + 已有 branch 历史）
- 修改 priority（数字输入或拖拽排序）
- 切换 isSkipped 状态

### F1-3 删除 Prompt
- 长按或滑动删除
- 确认对话框防误删

### F1-4 Prompt 列表视图
- 按 priority 升序显示
- 每条显示：内容摘要、branch 标签、状态 badge、priority
- 支持过滤：全部 / 待执行 / 已完成 / 已跳过

---

## F2 — Branch 视图

### F2-1 Branch 列表
- 列出所有 branch（从 prompt 聚合）
- 每个 branch 显示：名称、待执行数、已完成数
- 点击进入 branch 详情

### F2-2 Branch 详情 / 搜索
- 显示该 branch 下所有 prompt
- 过滤：已执行 / 未执行
- 在列表内直接调整 prompt priority（上下拖拽）

---

## F3 — 执行控制

### F3-1 开始执行
- 按 priority 升序获取所有 `pending` 且非 skipped 的 prompt
- 逐条切换 git branch 并调用 Claude Code CLI
- 实时显示执行进度（当前第几条/共几条）
- 执行成功 → status = done
- 执行失败 → status = failed，记录错误信息，继续下一条

### F3-2 暂停执行
- 当前 prompt 执行完后暂停（不强制中断）
- 状态变为 paused，可随时继续

### F3-3 执行日志
- 每条 prompt 的 Claude Code 输出可查看
- 失败时显示错误详情

---

## F4 — 设置与配置

### F4-1 Claude Code 路径配置
- 可自定义 `claude` CLI 的路径（默认从 PATH 查找）

### F4-2 工作目录配置
- 指定执行 prompt 时的 git 仓库根目录

---

## 实现优先级

| 优先级 | 功能 | 说明 |
|--------|------|------|
| P0 | F1-1, F1-2, F1-3, F1-4 | 基础 prompt CRUD，核心功能 |
| P0 | F3-1, F3-2 | 执行控制，项目核心价值 |
| P1 | F2-1, F2-2 | Branch 视图 |
| P1 | F4-1, F4-2 | 基础配置 |
| P2 | F3-3 | 执行日志查看 |

---

## 需要新增的依赖

```yaml
dependencies:
  drift: ^2.x          # 本地数据库
  sqlite3_flutter_libs: ^0.5.x
  uuid: ^4.x           # 生成 prompt ID
  path_provider: ^2.x  # 数据库文件路径
  path: ^1.x
```
