# 开发计划索引

本目录包含 **assisbant** 项目的完整开发计划。

## 项目简介

assisbant 是一个 Flutter 应用，通过 prompt 管理来控制 Claude Code 的执行，辅助完成日常开发工作。

## 计划文件

| 文件 | 内容 |
|------|------|
| [architecture.md](architecture.md) | 系统架构设计 |
| [data-model.md](data-model.md) | 数据模型设计 |
| [features.md](features.md) | 功能拆解与实现计划 |
| [ui-design.md](ui-design.md) | UI 结构与导航设计 |
| [milestones.md](milestones.md) | 里程碑与开发阶段 |

## 核心概念

- **Prompt**：一段任务描述，附带优先级、目标 branch、执行状态
- **Branch**：git 分支，作为 prompt 的执行目标
- **执行器**：按优先级顺序调用 Claude Code CLI 执行 prompt
