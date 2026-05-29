# assisbant セットアップガイド

## 動作環境

| ツール | バージョン | 用途 |
|---|---|---|
| macOS | 13 以上 | 主要ターゲット |
| Xcode | 14 以上 | macOS ビルド |
| Flutter (FVM) | 3.44.0 | フレームワーク |
| cmake | 3.15 以上 | stable_diffusion_ffi のビルド |

---

## 1. 事前ツールのインストール

```bash
# Homebrew（未インストールの場合）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# FVM（Flutter Version Manager）
brew tap leoafarias/fvm
brew install fvm

# cmake（stable-diffusion.cpp のビルドに必要）
brew install cmake

# Xcode Command Line Tools
xcode-select --install
```

---

## 2. リポジトリのクローンとセットアップ

```bash
# クローン
git clone https://github.com/normidar/assisbant.git
cd assisbant

# stable-diffusion.cpp サブモジュールを初期化（初回のみ）
git submodule update --init --recursive \
  packages/stable_diffusion_ffi/src/stable-diffusion.cpp

# Flutter 3.44.0 をインストール（初回のみ）
fvm install

# 依存パッケージを取得
fvm dart pub get
```

---

## 3. Native Assets の有効化

```bash
fvm flutter config --enable-native-assets
```

> **注意:** この設定は一度だけ実行すれば OK です。
> `libstable-diffusion.dylib` は `flutter build` 時に cmake で自動コンパイルされます。

---

## 4. ビルド・実行

### 開発（ホットリロードあり）
```bash
fvm flutter run -d macos
```

### リリースビルド
```bash
fvm flutter build macos
# → build/macos/Build/Products/Release/assibant.app
```

---

## 5. よく使うコマンド

```bash
fvm dart pub get              # パッケージ取得
fvm dart analyze              # 静的解析
fvm flutter test              # テスト実行
```

---

## 6. モデルファイルの配置

ローカル画像生成（Local モード）を使用する場合は `.gguf` モデルファイルが必要です。

アプリを一度起動した後、以下のフォルダにファイルを配置してください：

```
~/Library/Application Support/assibant/models/
```

または、アプリ内の **設定 → 画像生成 → 変更…** からダウンロードできます。

### 推奨モデル（HuggingFace より）

```bash
# Realistic Vision V6.0 B1（フォトリアル、約 1.8 GB）
huggingface-cli download second-state/Realistic_Vision_V6.0_B1-GGUF \
  realisticVisionV60B1_v51HyperVAE-Q8_0.gguf \
  --local-dir ~/Library/Application\ Support/assibant/models/

# Stable Diffusion 1.5（汎用、約 1.6 GB）
huggingface-cli download second-state/stable-diffusion-v1-5-GGUF \
  stable-diffusion-v1-5-pruned-emaonly-Q4_0.gguf \
  --local-dir ~/Library/Application\ Support/assibant/models/
```

---

## トラブルシューティング

| 問題 | 解決方法 |
|---|---|
| `fvm` が見つからない | `export PATH="$PATH:$HOME/.pub-cache/bin"` を `.zshrc` に追加 |
| cmake が見つからない | `brew install cmake` |
| ビルドエラー（Metal 関連） | Xcode を最新版にアップデート |
| モデルが認識されない | ファイルの拡張子が `.gguf` であることを確認 |