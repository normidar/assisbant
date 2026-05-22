# assisbant

**一款 macOS 桌面应用，用于跨 git 分支管理和批量执行 Claude Code 提示词。**

[![Flutter](https://img.shields.io/badge/Flutter-3.38.8-02569B?logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-macOS-black?logo=apple)](https://developer.apple.com/macos/)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

> 将你的 Claude Code 工作流转化为托管队列 —— 创建提示词、指定分支、设置优先级，剩下的交给 assisbant 自动完成。

---

### 无人值守，全天候执行数百个 AI 任务

有本地模型和 200 个编程任务积压？**assisbant 就是为此而生的。**

睡前把所有任务加入队列。醒来就能看到完整的执行历史、每个任务的日志，以及一个彩色状态看板，清晰显示哪些通过了、哪些需要再看一眼。无需守着终端，无需手动切换分支，只要结果。

> AI 辅助开发的"设好就忘"方案 —— 特别适合 24 小时运行、无速率限制和 API 费用的本地 LLM 环境（Ollama、LM Studio、llama.cpp）。

---

## 什么是 assisbant？

使用 [Claude Code](https://claude.ai/code) 时，你经常需要在不同功能分支上依次运行多个提示词，而无需一直盯着终端。**assisbant** 为此提供了一个可视化的队列管理器。

- 提前编写提示词，指定目标分支和优先级
- 点击「Run」—— 应用通过 `claude --print` 逐一执行
- 在内置终端视图中实时查看输出流
- 执行完毕后，查看清晰的成功/失败汇总与完整日志

---

## 截图

![提示词页面](screenshot/prompts_page.png)

![分支页面](screenshot/branch_page.png)

![批量创建](screenshot/batch_create.png)

![批量创建（已填写）](screenshot/batch_create2.png)

![日志页面](screenshot/log_page.png)

![设置页面](screenshot/settings_page.png)

---

## 功能

### 提示词队列管理
- 创建包含**内容**、**目标分支**和**优先级**的提示词
- 拖拽调整执行优先级
- **批量创建** —— 粘贴多行文本，每行即可瞬间变成一条提示词
- 跳过单条提示词而不删除
- 将已完成/失败的提示词重置为待执行状态

### 执行引擎
- 顺序执行 `claude --dangerously-skip-permissions --print "<内容>"`
- **自动检出** —— 在每条提示词执行前自动切换 git 分支
- **失败时暂停** —— 提示词执行失败时停止队列，便于检查后继续
- 将 stdout/stderr 实时流式传输到应用内终端视图
- 每条提示词的 `projectPath` 可覆盖全局工作目录

### 分支视图
- 以彩色进度条可视化展示所有分支
- 一目了然：每个分支的待执行/已完成/失败数量
- 点击分支即可立即过滤提示词列表

### 会话追踪
- 通过**会话 ID** 对相关提示词进行分组（自动生成 `silver-fox`、`morning-maple` 等富有创意的名称）
- 按会话 ID、分支或项目路径过滤和搜索
- 每条提示词存储 `claudeSessionId`，便于与 Claude Code 运行记录交叉引用

### 执行日志
- 专用日志页面，配备终端风格查看器
- 每条提示词的完整 stdout/stderr 历史
- 可选中文本进行复制粘贴

### 设置
| 设置项 | 说明 |
|---|---|
| CLI 路径 | `claude` 可执行文件的路径 |
| 工作目录 | `git checkout` 和提示词执行的默认目录 |
| 自动检出 | 在每条提示词执行前自动切换分支 |
| 失败时暂停 | 提示词失败时停止队列 |
| 语言 | English / 中文 / 日本語 |
| 主题 | 浅色 / 深色 |

---

## 安装

### 环境要求

- macOS 12 及以上
- [Flutter](https://flutter.dev)（或 [FVM](https://fvm.app) —— 推荐）
- 已安装并添加到 PATH 的 [Claude Code CLI](https://claude.ai/code)

### 从源码构建

```bash
# 克隆仓库
git clone https://github.com/normidar/assisbant.git
cd assisbant

# 如需安装 FVM（Flutter 版本管理器）
dart pub global activate fvm
fvm install

# 获取依赖
fvm flutter pub get

# 运行代码生成（Drift + Riverpod）
fvm dart run build_runner build --delete-conflicting-outputs

# 构建 macOS 版本
fvm flutter build macos

# 或以开发模式运行
fvm flutter run -d macos
```

构建好的应用位于 `build/macos/Build/Products/Release/assisbant.app`。

---

## 使用方法

### 1. 配置 CLI 路径

打开**设置**，填写 `claude` 可执行文件的路径（默认：`/usr/local/bin/claude`）和工作目录（你的 git 仓库根目录）。

### 2. 创建提示词

在提示词页面点击 **+ 新建提示词**，填写：

- **内容** —— 要传给 Claude Code 的指令
- **分支** —— 执行该提示词的 git 分支
- **优先级** —— 数值越大越先执行
- **会话 ID** —— 可选的分组标签
- **项目路径** —— 仅覆盖该提示词的全局工作目录

### 3. 批量创建

点击**批量创建**，一次性粘贴或输入多条提示词 —— 每行一条，一键全部添加。

### 4. 运行队列

在底部执行栏按下 **Run**，assisbant 将：

1. 按优先级（从高到低）对待执行提示词排序
2. 对每条提示词：可选执行 `git checkout <分支>`，然后调用 `claude --print "<内容>"`
3. 实时流式传输输出，并将结果存入 SQLite
4. 将每条提示词标记为「已完成」或「失败」

### 5. 查看结果

切换到**日志**标签，查看所有执行的可搜索历史记录及完整输出。

---

## 架构

```
UI（screens/ + widgets/）
  └── Riverpod 提供者（state/）
        └── 仓库 & 服务（data/）
              └── SQLite（Drift）+ claude CLI 进程
```

| 层级 | 技术 |
|---|---|
| UI | Flutter + Material 3 |
| 状态管理 | Flutter Riverpod（手动 + 生成） |
| 数据库 | Drift（SQLite，schema v5） |
| 持久化 | SharedPreferences（设置） |
| 国际化 | 自定义 `AppStrings`（EN / ZH / JA） |
| CLI 集成 | `dart:io Process.start` 流式传输 |

---

## 开发

```bash
make get        # fvm dart pub get
make build      # build_runner 代码生成（修改 schema / @Riverpod 后运行）
make analyze    # dart analyze
make format     # dart format + markdown prettier
make ci         # 完整 CI 流水线
```

**测试：**
```bash
fvm flutter test
```

Drift 测试使用内存数据库 —— 无需外部环境配置。

---

## 贡献

欢迎提交 Pull Request！贡献前请：

1. 运行 `make ci` 并确保通过
2. 为修改的逻辑添加或更新测试
3. 保持架构分层 —— UI 不得直接调用仓库层

---

## 许可证

MIT 许可证。详见 [LICENSE](LICENSE)。

---

<p align="center">基于 Flutter for macOS 构建 · 由 Claude Code 驱动</p>
