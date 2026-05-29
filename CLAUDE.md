# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**assisbant** is a macOS-focused Flutter desktop application for managing and executing Claude Code CLI prompts across git branches. Users create prompts with target branches and priorities, then the app executes them sequentially via `claude --print "<content>"` in a configured working directory.

The package name in Dart imports is `assibant`. The primary target is **macOS desktop**, but `ios/` and `android/` directories also exist for the mobile companion app (see `lib/mobile_main.dart`), which lets a phone remotely control the Mac app over WebSocket.

## FVM (Flutter Version Manager)

This project uses **FVM** to pin Flutter to version **3.38.8**. You **must** always prefix Flutter/Dart commands with `fvm`:

| Instead of | Use |
|---|---|
| `flutter ...` | `fvm flutter ...` |
| `dart ...` | `fvm dart ...` |
| `dart fix --apply .` | `fvm dart fix --apply .` |
| `dart analyze` | `fvm dart analyze` |

Never run bare `flutter` or `dart` — it may pick up the wrong SDK version.

## Important Rules

毎回変更が発生した後に、実行できるファイルをビルドしてください。
Run `fvm flutter build macos` after every code change to produce an up-to-date executable.

`prompt_edit_modal.dart` (Create/Edit Prompt screen) に変更を加えた場合、同じ変更を `batch_create_modal.dart` (Batch Create screen) にも必ず適用してください。両ファイルは同じフォームUI（project path, branch, session ID 等）を持つため、常に同期して変更する必要があります。

## Commands

```bash
make get            # fvm dart pub get
make build          # build_runner codegen (required after Drift schema or @Riverpod changes)
make build_windows  # build Windows release and copy to build/exe/
make analyze        # fvm dart analyze
make format         # dart format + prettier for markdown
make ci             # full CI: get → localization → build → analyze → format → gen_icons
```

**Tests:**
```bash
fvm flutter test                                                     # all tests
fvm flutter test test/data/repositories/prompt_repository_test.dart # single file
```

Drift tests use `NativeDatabase.memory()` — no setup needed.

**macOS development:**
```bash
fvm flutter run -d macos
make init_macos   # if macos/ platform directory doesn't exist yet
```

## Architecture

### Layer overview

```
UI (screens/ + widgets/) → State (state/) → Repository/Service (data/) → SQLite + claude CLI
```

All layers communicate strictly upward — UI reads from Riverpod providers, never touches repositories directly.

### Riverpod state (two styles coexist)

**Manual `NotifierProvider`** (no code generation, no `part` file):
- `lib/src/state/ui_providers.dart` — tab, language, filter, search, selectedPromptId, branchFilter, `SettingsNotifier`
- `lib/src/state/exec_notifier.dart` — `ExecNotifier` (execution loop)
- `lib/src/state/prompt_notifier.dart` — `PromptListNotifier` (AsyncNotifier)

**Generated `@Riverpod`** (requires `make build` after changes):
- `lib/src/providers/database_providers.dart` — `appDatabaseProvider`, `promptRepositoryProvider`, `executionServiceProvider`

### Settings persistence

`AppSettings` (`cliPath`, `workdir`, `autoCheckout`, `pauseOnFail`, `commitAfterPrompt`, `remoteEnabled`, `remotePort`, `envOverrides`, and more) is persisted via SharedPreferences. The flow:
1. `normal_main.dart` awaits `SharedPreferences.getInstance()` before `runApp`
2. Injects it via `ProviderScope(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)])`
3. `SettingsNotifier.build()` reads from `sharedPreferencesProvider` synchronously
4. `SettingsNotifier.update()` persists to SharedPreferences and updates state

The `sharedPreferencesProvider` lives in `lib/src/providers/prefs_provider.dart` (separate file to avoid a circular import: `execution_service.dart` imports `ui_providers.dart` for `AppSettings`).

### Execution engine

`ExecNotifier._runLoop()` iterates the queue sequentially:
1. `repo.updateStatus(id, running)` → invalidate `promptListNotifierProvider`
2. `ExecutionService.run(prompt, settings)` — calls `git checkout <branch>` (if `autoCheckout`) then `claude --dangerously-skip-permissions --print "<content>"` via `dart:io Process.start` (streaming)
3. `repo.updateStatus(id, done/failed)` + `repo.updateOutput(id, stdout/stderr)`
4. If `pauseOnFail` and failed → awaits a `Completer<void>` until `resume()` or `stop()`

Pause/resume uses `Completer<void>? _pauseCompleter`. Stop sets `_stopRequested = true` and completes the completer. Each prompt's `projectPath` overrides the global `workdir` if set.

### Database (Drift / SQLite)

Schema version: **9**. Two tables: `prompts` (columns: `id, content, branch, priority, status, is_skipped, output, project_path, session_id, claude_session_id, claude_model, image_paths, commit_after_run, started_at, created_at, updated_at`) and `image_gen_records` (Stable Diffusion generation history).

When changing schema: bump `schemaVersion`, add a migration case in `MigrationStrategy.onUpgrade`, then run `make build`.

`BranchSummary` is never stored — it's aggregated from `PromptRepository.getBranchSummaries()` by grouping all prompts by branch.

### Responsive layout

`AppShell` branches on `MediaQuery width > 720`:
- **Desktop**: 240 px fixed sidebar (`_Sidebar`) + content area + bottom `ExecBar`
- **Mobile**: full-screen content + compact exec strip + `NavigationBar`

The sidebar includes per-branch quick links that set `branchFilterProvider`, causing `PromptsScreen` to filter its list without navigating away.

### i18n

Custom class `AppStrings` in `lib/src/i18n/app_strings.dart` — **not** `easy_localization` (the package is present but unused for this). EN, ZH, and JA are static const instances. Add new strings to all three (`_en`, `_zh`, `_ja`) AND to the constructor parameter list and the field declaration.

### Prompt edit rules

- **Editable**: `status == pending || isSkipped`
- **Skip/Unskip**: `status != running && status != done`
- **Reset to pending**: `status == done || status == failed`
- **Running** prompts: no actions except delete
