# assisbant

**git ブランチをまたいで Claude Code プロンプトを管理・一括実行する macOS デスクトップアプリ。**

[![Flutter](https://img.shields.io/badge/Flutter-3.38.8-02569B?logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-macOS-black?logo=apple)](https://developer.apple.com/macos/)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

> Claude Code のワークフローをマネージドキューに変える — プロンプトを作成し、ブランチを割り当て、優先度を設定すれば、あとは assisbant が自動で処理します。

---

### 何百もの AI タスクを — 放置したまま、24 時間動かし続ける

ローカルモデルと 200 件のコーディングタスクのバックログがある？ **assisbant はまさにそのために作られました。**

寝る前にすべてをキューに積んでください。起きたら実行履歴、タスクごとのログ、そして何が通って何を見直すべきかが一目でわかるカラーコードのステータスボードが出来上がっています。ターミナルの監視不要。手動のブランチ切り替え不要。結果だけ。

> AI 支援開発のための「セットして忘れる」仕組み — レート制限や API コストなしに 24 時間稼働するローカル LLM 環境（Ollama、LM Studio、llama.cpp）に最適です。

---

## assisbant とは？

[Claude Code](https://claude.ai/code) を使っていると、異なるフィーチャーブランチをまたいで複数のプロンプトを順番に実行したくなることがよくあります。ターミナルを張り付いて監視するのは手間がかかります。**assisbant** はそのためのビジュアルなキューマネージャーです。

- プロンプトをあらかじめ書いておき、対象ブランチと優先度を設定
- 「Run」を押すだけ — アプリが `claude --print` で一つずつ実行
- 組み込みのターミナルビューでライブ出力をストリーム表示
- 終わったら、成功・失敗の一覧とフルログをまとめて確認

---

## スクリーンショット

![プロンプト画面](screenshot/prompts_page.png)

![ブランチ画面](screenshot/branch_page.png)

![一括作成](screenshot/batch_create.png)

![一括作成（入力済み）](screenshot/batch_create2.png)

![ログ画面](screenshot/log_page.png)

![設定画面](screenshot/settings_page.png)

---

## 機能

### プロンプトキュー管理
- **内容**・**対象ブランチ**・**優先度**を指定してプロンプトを作成
- ドラッグ＆ドロップで実行順序を並び替え
- **一括作成** — 複数行のテキストを貼り付けるだけで、各行がプロンプトになる
- 削除せずに個別のプロンプトをスキップ
- 完了・失敗したプロンプトをペンディングに戻してリセット

### 実行エンジン
- `claude --dangerously-skip-permissions --print "<内容>"` を順番に実行
- **自動チェックアウト** — 各プロンプトの前に git ブランチを自動切り替え
- **失敗時に一時停止** — プロンプトが失敗するとキューを止めて確認・再開できる
- リアルタイムの stdout/stderr をアプリ内ターミナルにストリーム表示
- プロンプトごとの `projectPath` でグローバルな作業ディレクトリを上書き可能

### ブランチビュー
- すべてのブランチをカラーコードの進捗バーでビジュアル表示
- ブランチごとのペンディング・完了・失敗の件数を一目で確認
- ブランチをクリックしてプロンプトリストを即時フィルタリング

### セッション管理
- **セッション ID** で関連するプロンプトをグループ化（`silver-fox`・`morning-maple` のようなユニークな名前を自動生成）
- セッション ID・ブランチ・プロジェクトパスで絞り込み・検索
- `claudeSessionId` をプロンプトごとに保存して Claude Code の実行履歴と照合

### 実行ログ
- ターミナル風ビューア付きの専用ログ画面
- プロンプトごとの stdout/stderr の全履歴
- テキスト選択してコピー＆ペースト可能

### 設定
| 設定項目 | 説明 |
|---|---|
| CLI パス | `claude` 実行ファイルのパス |
| 作業ディレクトリ | `git checkout` とプロンプト実行のデフォルトディレクトリ |
| 自動チェックアウト | 各プロンプトの前に自動でブランチを切り替える |
| 失敗時に一時停止 | プロンプトが失敗したらキューを停止する |
| 言語 | English / 中文 / 日本語 |
| テーマ | ライト / ダーク |

---

## インストール

### 必要環境

- macOS 12 以上
- [Flutter](https://flutter.dev)（または [FVM](https://fvm.app) — 推奨）
- PATH に追加済みの [Claude Code CLI](https://claude.ai/code)

### ソースからビルド

```bash
# リポジトリをクローン
git clone https://github.com/normidar/assisbant.git
cd assisbant

# FVM（Flutter Version Manager）がなければインストール
dart pub global activate fvm
fvm install

# 依存パッケージを取得
fvm flutter pub get

# コード生成を実行（Drift + Riverpod）
fvm dart run build_runner build --delete-conflicting-outputs

# macOS 向けにビルド
fvm flutter build macos

# または開発モードで起動
fvm flutter run -d macos
```

ビルドされたアプリは `build/macos/Build/Products/Release/assisbant.app` に出力されます。

---

## 使い方

### 1. CLI パスを設定する

**設定**を開き、`claude` 実行ファイルのパス（デフォルト: `/usr/local/bin/claude`）と作業ディレクトリ（git リポジトリのルート）を設定します。

### 2. プロンプトを作成する

プロンプト画面の **+ 新規プロンプト** をクリックして入力します。

- **内容** — Claude Code に渡す指示
- **ブランチ** — 実行対象の git ブランチ
- **優先度** — 数値が大きいほど先に実行
- **セッション ID** — 任意のグループラベル
- **プロジェクトパス** — このプロンプトだけグローバルの作業ディレクトリを上書き

### 3. 一括作成

**一括作成**をクリックして複数のプロンプトを一度にまとめて追加できます。1行1プロンプトで入力します。

### 4. キューを実行する

下部の実行バーで **Run** を押します。assisbant は以下の順で処理します。

1. ペンディングのプロンプトを優先度の高い順にソート
2. 各プロンプトに対して: 必要なら `git checkout <ブランチ>` → `claude --print "<内容>"` を呼び出し
3. 出力をライブでストリームしながら結果を SQLite に保存
4. プロンプトを「完了」または「失敗」としてマーク

### 5. 結果を確認する

**ログ**タブで全実行の検索可能な履歴とフルの出力を確認できます。

---

## アーキテクチャ

```
UI (screens/ + widgets/)
  └── Riverpod プロバイダー (state/)
        └── リポジトリ & サービス (data/)
              └── SQLite (Drift) + claude CLI プロセス
```

| レイヤー | 技術 |
|---|---|
| UI | Flutter + Material 3 |
| 状態管理 | Flutter Riverpod（手動 + 生成） |
| データベース | Drift（SQLite、スキーマ v5） |
| 永続化 | SharedPreferences（設定） |
| i18n | カスタム `AppStrings`（EN / ZH / JA） |
| CLI 連携 | `dart:io Process.start` ストリーミング |

---

## 開発

```bash
make get        # fvm dart pub get
make build      # build_runner コード生成（スキーマ / @Riverpod 変更後に実行）
make analyze    # dart analyze
make format     # dart format + markdown prettier
make ci         # CI パイプライン一括実行
```

**テスト:**
```bash
fvm flutter test
```

Drift のテストはインメモリデータベースを使用 — 外部のセットアップは不要です。

---

## コントリビュート

プルリクエストは歓迎です！ コントリビュートの前に以下をお願いします。

1. `make ci` を実行してパスすることを確認
2. 変更したロジックにテストを追加・更新
3. アーキテクチャのレイヤーを守る — UI からリポジトリを直接呼び出さない

---

## ライセンス

MIT ライセンス。詳細は [LICENSE](LICENSE) を参照してください。

---

<p align="center">Flutter for macOS で構築 · Claude Code で動作</p>
