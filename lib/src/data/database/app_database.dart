import 'package:assibant/src/data/database/prompt_status.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

@DataClassName('ImageGenRecord')
class ImageGenRecords extends Table {
  TextColumn get id => text()();
  TextColumn get prompt => text()();
  TextColumn get negativePrompt => text().withDefault(const Constant(''))();
  TextColumn get model => text().withDefault(const Constant(''))();
  IntColumn get width => integer().withDefault(const Constant(512))();
  IntColumn get height => integer().withDefault(const Constant(512))();
  IntColumn get seed => integer().nullable()();
  IntColumn get steps => integer().withDefault(const Constant(20))();
  IntColumn get generationTimeMs => integer().withDefault(const Constant(0))();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get finishedAt => dateTime()();
  TextColumn get imagePath => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('success'))();
  TextColumn get errorMessage => text().nullable()();
  IntColumn get iteration => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class PromptStatusConverter extends TypeConverter<PromptStatus, String> {
  const PromptStatusConverter();

  @override
  PromptStatus fromSql(String fromDb) =>
      PromptStatus.values.firstWhere((e) => e.name == fromDb);

  @override
  String toSql(PromptStatus value) => value.name;
}

/// プロンプトを格納するメインテーブル。Drift が PromptEntry データクラスを自動生成する。
@DataClassName('PromptEntry')
class Prompts extends Table {
  TextColumn get id => text()(); // UUID v4
  TextColumn get content => text()(); // Claude に渡すプロンプト本文
  TextColumn get branch => text()(); // 実行対象の git ブランチ名
  IntColumn get priority =>
      integer().withDefault(const Constant(0))(); // 小さい値が先に実行される
  TextColumn get status => text()
      .withDefault(const Constant('pending'))
      .map(const PromptStatusConverter())(); // pending/running/done/failed
  BoolColumn get isSkipped =>
      boolean().withDefault(const Constant(false))(); // true のとき実行キューをスキップ
  TextColumn get output => text().nullable()(); // 実行後の stdout/stderr
  TextColumn get projectPath =>
      text().withDefault(const Constant(''))(); // 空の場合はグローバル workdir を使用
  // ユーザーが定義する会話グループID。同じ sessionId のプロンプトは Claude の会話を引き継ぐ
  TextColumn get sessionId => text().withDefault(const Constant(''))();
  // Claude CLI が返す内部セッションID。--resume フラグに渡して会話を継続する
  TextColumn get claudeSessionId => text().withDefault(const Constant(''))();
  TextColumn get claudeModel =>
      text().withDefault(const Constant(''))(); // 空の場合はデフォルトモデル
  TextColumn get imagePaths =>
      text().withDefault(const Constant(''))(); // JSON配列文字列
  BoolColumn get commitAfterRun =>
      boolean().withDefault(const Constant(false))(); // 実行後に自動コミットするか
  DateTimeColumn get startedAt => dateTime().nullable()(); // 実行開始時刻（未実行は null）
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [Prompts, ImageGenRecords])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 9;

  /// カラム追加のみの段階的マイグレーション。
  /// スキーマを変更したら schemaVersion を +1 し、新しい if (from < N) ブロックを追加する。
  /// テーブル再作成なしで ALTER TABLE ADD COLUMN する方針のため、削除・型変更は不可。
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(prompts, prompts.output as GeneratedColumn<Object>);
      }
      if (from < 3) {
        await m.addColumn(
          prompts,
          prompts.projectPath as GeneratedColumn<Object>,
        );
      }
      if (from < 4) {
        // 会話継続機能の追加 (sessionId: ユーザー定義, claudeSessionId: Claude内部)
        await m.addColumn(
          prompts,
          prompts.sessionId as GeneratedColumn<Object>,
        );
        await m.addColumn(
          prompts,
          prompts.claudeSessionId as GeneratedColumn<Object>,
        );
      }
      if (from < 5) {
        await m.addColumn(
          prompts,
          prompts.startedAt as GeneratedColumn<Object>,
        );
      }
      if (from < 6) {
        await m.addColumn(
          prompts,
          prompts.claudeModel as GeneratedColumn<Object>,
        );
      }
      if (from < 7) {
        await m.addColumn(
          prompts,
          prompts.imagePaths as GeneratedColumn<Object>,
        );
      }
      if (from < 8) {
        await m.addColumn(
          prompts,
          prompts.commitAfterRun as GeneratedColumn<Object>,
        );
      }
      if (from < 9) {
        await m.createTable(imageGenRecords);
      }
    },
  );

  static QueryExecutor _openConnection() => driftDatabase(name: 'assisbant_db');
}
