# セットアップ手順

## 既存のアプリプロジェクトに適用する場合

- [ ] lib ディレクトリを移動する
- [ ] 各システムのフォルダを移動する
- [ ] pubspec.yaml を移動する
- [ ] make get を実行する
- [ ] assets/localizations 内の内容を整備する
- [ ] make tr を実行して、fastlane とネイティブコードの変更を確認する
- もし自動スクリーンショットが必要な場合
  - [ ] スクショを生成するコードを追加する
  - [ ] assets/config.yaml の内容を変更して自動スクショを起動する
- もし normidar のアカウントではない場合
  - [ ] fastlane-key.json を作成する
  - [ ] fastlane/AuthKey\_〇〇〇.p8 を作成する
  - [ ] fastlane/Fastfile を編集する
  - [ ] fastlane/Appfile を編集する
- もしバージョンが低い場合
  - [ ] fvm use <古いバージョン> を実行して、古いバージョンに戻す
- Android の場合
  - [ ] key.propertiesをコピペ
  - [ ] upload-keystore.jksをコピペ

## 新規プロジェクトを作成する場合

- [ ] make rename newname を実行して、プロジェクト名を変更する
- [ ] make init\_〇〇 を実行して該当ネイティブのプロジェクトを作成する
  - [ ] make init_android を実行する
  - [ ] make init_ios を実行する
  - [ ] make init_web を実行する
  - [ ] make init_macos を実行する
- [ ] make get を実行する
- [ ] assets/localizations 内の内容を整備する
- [ ] make tr を実行して、fastlane とネイティブコードの変更を確認する
- [ ] スクショを生成するコードを追加する
- [ ] assets/config.yaml の内容を変更して自動スクショを起動してスクショを撮る
