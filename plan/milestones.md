# 里程碑与开发阶段

## M1 — 基础脚手架（数据层）

**目标**：完成数据模型和本地存储，无 UI 可跑测试。

- [ ] 添加 Drift、uuid、path_provider 依赖
- [ ] 定义 `prompts` 数据库表（Drift Table）
- [ ] 实现 `PromptRepository`（CRUD + 按 priority/branch 查询）
- [ ] 编写 Repository 单元测试
- [ ] 实现 `BranchSummary` 聚合逻辑

---

## M2 — Prompt 管理 UI（P0 功能）

**目标**：能够创建、编辑、删除、列举 prompt，数据持久化。

- [ ] 接入 Riverpod，创建 `PromptListNotifier`
- [ ] 实现 `PromptListPage`（列表 + 过滤 chip）
- [ ] 实现 `PromptCard` 组件
- [ ] 实现 `PromptEditPage`（新建/编辑表单）
- [ ] Branch 历史快捷选择

---

## M3 — 执行引擎（P0 功能）

**目标**：能够按 priority 顺序调用 Claude Code CLI 执行 prompt。

- [ ] 实现 `ExecutionService`（Process 调用 claude CLI）
- [ ] 实现 `ExecutionNotifier`（start / pause / resume）
- [ ] 实现执行控制栏 UI（进度显示）
- [ ] 执行成功/失败状态写回数据库
- [ ] Settings 页面：配置 Claude CLI 路径和工作目录

---

## M4 — Branch 视图（P1 功能）

**目标**：能够按 branch 查看和管理 prompt。

- [ ] 实现 `BranchListNotifier`（从 prompt 派生）
- [ ] 实现 `BranchListPage` + `BranchCard`
- [ ] 实现 `BranchDetailPage`（含 prompt 过滤和拖拽排序）

---

## M5 — 完善与发布

**目标**：体验优化，准备发布。

- [ ] 执行日志查看页面（F3-3）
- [ ] 错误处理与用户反馈（toast / dialog）
- [ ] 多语言支持（中文 + 英文，使用 easy_localization）
- [ ] 应用图标与启动页
- [ ] 响应式布局适配（平板/桌面）
- [ ] 整体 UI 打磨

---

## 当前状态

- 项目使用 Flutter + Riverpod + easy_localization 模板初始化
- 已有 `colaxy_adaptive_scaffold` 可用于响应式布局
- **下一步**：从 M1 开始，添加 Drift 并搭建数据层
