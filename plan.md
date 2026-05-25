# 修正計画 (assisbant)

調査日: 2026-05-23

---

## クリティカル

### C-1: `archive` パッケージが pubspec.yaml に未定義
**場所:** `pubspec.yaml` / `lib/src/data/services/import_export_service.dart`

`import_export_service.dart` の `exportToExcel()` 内で `package:archive/archive.dart` を import しているが、
`pubspec.yaml` の dependencies に `archive` が存在しない。
Excel エクスポートを実行すると実行時クラッシュになる。

**修正方針:**
```yaml
dependencies:
  archive: ^3.6.0
```
を pubspec.yaml に追加し、`fvm dart pub get` を実行する。

---

### C-2: `PromptStatus` enum に `skipped` が存在しない
**場所:** `lib/src/data/database/prompt_status.dart`

```dart
enum PromptStatus { pending, running, done, failed }
// "skipped" がない
```

UI 側のフィルター (`filterSkipped`)・ステータスバッジ (`statusSkipped`) では「スキップ」を表示しているが、
DB 上は `isSkipped` boolean で管理されており意味論的に不整合。

**修正方針 (選択肢):**

**Option A (推奨):** enum に手を加えず、フィルター処理を `isSkipped == true` として現状のまま明示的にドキュメント化する。
`prompt_status.dart` に `/// Skipped state is tracked via isSkipped boolean, not this enum` を追記。

**Option B:** `skipped` を enum に追加し、`isSkipped` boolean を廃止してマイグレーションで移行する（スキーマ v9）。
影響範囲が大きいため慎重に検討が必要。

---

## 高優先度

### H-1: CLAUDE.md のスキーマバージョンが古い
**場所:** `CLAUDE.md` 97行目

```
Schema version: **4**.
```
と書かれているが、実際は `app_database.dart` にて `schemaVersion => 8` になっている。

**修正方針:** CLAUDE.md を v8 に更新し、v5〜v8 で追加された列（`startedAt`, `claudeModel`, `imagePaths`, `commitAfterRun`）を記載する。

---

### H-2: 空のテストテンプレートファイルが残っている
**場所:** `test/main_test.dart`, `test/widget_test.dart`

どちらも Flutter プロジェクト初期テンプレートのままで、テスト内容が一切ない。
`fvm flutter test` を実行するとこれらが失敗する可能性がある。

**修正方針:** 削除するか、最低限の smoke test を実装する。

---

### H-3: `ExecNotifier` 内の Completer リーク懸念
**場所:** `lib/src/state/exec_notifier.dart`

```dart
Completer<void>? _pauseCompleter;
Completer<void>? _cancelCurrentRun;
Completer<String>? _questionCompleter;
```

実行が異常終了した場合に各 Completer が適切にクリアされるか確認が必要。
特に `_cancelCurrentRun` と `_questionCompleter` は finally ブロックで null 代入されているか要チェック。

**修正方針:** `_runLoop()` の finally ブロックで全 Completer を null クリアするコードを追加・確認する。

---

## 中優先度

### M-1: 未使用の `easy_localization` 依存が残っている
**場所:** `pubspec.yaml`, `assets/localizations/en-US.json`

CLAUDE.md に「easy_localization は未使用」と明記されているが、
pubspec.yaml には依存が存在し、assets に JSON ファイルも残っている。
i18n は `AppStrings` クラスで完結している。

**修正方針:** `easy_localization` と関連アセットを pubspec.yaml から削除し、`assets/localizations/` ディレクトリを削除する。

---

### M-2: テストカバレッジが Repository 層のみ
**場所:** `test/`

現状のテスト:
- `prompt_repository_test.dart` ✓ (12グループ、充実)
- `ExecNotifier` ✗ 未テスト
- `ImportExportService` ✗ 未テスト
- UI スクリーン群 ✗ 未テスト

**修正方針 (優先順):**
1. `ExecNotifier` の unit test（pause/resume/stop ロジック）
2. `ImportExportService` の unit test（JSON import/export）
3. 主要 screen の widget test（PromptsScreen, SettingsScreen）

---

### M-3: 2つのモーダルの同期リスク
**場所:** `prompt_edit_modal.dart` / `batch_create_modal.dart`

現時点では同期が取れているが、共通フォーム部品（project path, branch, session ID など）に変更を加える際、
両ファイルへの適用を忘れると乖離が発生する。

**修正方針:** CLAUDE.md の同期ルールは既に記載済み。
追加対応として `prompt_form_shared.dart` への共通部品のさらなる抽出を検討する。

---

## 低優先度

### L-1: `imagePaths` が JSON 文字列としてカラムに保存されている
**場所:** `lib/src/data/database/app_database.dart`

画像パスリストを JSON 文字列として TEXT カラムに格納している。
型安全でなく、将来的にパースエラーが発生しうる。

**修正方針:** Drift の `TextColumn` に `map()` でカスタム TypeConverter を実装し、
`List<String>` との自動変換を行う（既に他の converter のパターンが存在するなら参考にする）。

---

## 修正優先順位まとめ

| 優先度 | ID | タイトル | 工数 |
|--------|-----|---------|------|
| 🔴 Critical | C-1 | archive 依存追加 | 小 |
| 🔴 Critical | C-2 | isSkipped/PromptStatus 整理 | 中〜大 |
| 🟠 High | H-1 | CLAUDE.md スキーマバージョン更新 | 小 |
| 🟠 High | H-2 | 空テストファイル削除 | 小 |
| 🟠 High | H-3 | Completer クリーンアップ確認 | 小〜中 |
| 🟡 Medium | M-1 | easy_localization 削除 | 小 |
| 🟡 Medium | M-2 | テストカバレッジ拡充 | 大 |
| 🟡 Medium | M-3 | モーダル共通部品抽出 | 中 |
| 🟢 Low | L-1 | imagePaths TypeConverter | 小 |
