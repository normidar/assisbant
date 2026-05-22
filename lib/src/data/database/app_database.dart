import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutterapptemp/src/data/database/prompt_status.dart';

part 'app_database.g.dart';

class PromptStatusConverter extends TypeConverter<PromptStatus, String> {
  const PromptStatusConverter();

  @override
  PromptStatus fromSql(String fromDb) =>
      PromptStatus.values.firstWhere((e) => e.name == fromDb);

  @override
  String toSql(PromptStatus value) => value.name;
}

@DataClassName('PromptEntry')
class Prompts extends Table {
  TextColumn get id => text()();
  TextColumn get content => text()();
  TextColumn get branch => text()();
  IntColumn get priority =>
      integer().withDefault(const Constant(0))();
  TextColumn get status => text()
      .withDefault(const Constant('pending'))
      .map(const PromptStatusConverter())();
  BoolColumn get isSkipped =>
      boolean().withDefault(const Constant(false))();
  TextColumn get output => text().nullable()();
  TextColumn get projectPath => text().withDefault(const Constant(''))();
  TextColumn get sessionId => text().withDefault(const Constant(''))();
  TextColumn get claudeSessionId => text().withDefault(const Constant(''))();
  TextColumn get claudeModel => text().withDefault(const Constant(''))();
  TextColumn get imagePaths => text().withDefault(const Constant(''))();
  BoolColumn get commitAfterRun =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [Prompts])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 8;

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
        await m.addColumn(
          prompts, prompts.sessionId as GeneratedColumn<Object>);
        await m.addColumn(
          prompts, prompts.claudeSessionId as GeneratedColumn<Object>);
      }
      if (from < 5) {
        await m.addColumn(
          prompts, prompts.startedAt as GeneratedColumn<Object>);
      }
      if (from < 6) {
        await m.addColumn(
          prompts, prompts.claudeModel as GeneratedColumn<Object>);
      }
      if (from < 7) {
        await m.addColumn(
          prompts, prompts.imagePaths as GeneratedColumn<Object>);
      }
      if (from < 8) {
        await m.addColumn(
          prompts, prompts.commitAfterRun as GeneratedColumn<Object>);
      }
    },
  );

  static QueryExecutor _openConnection() =>
      driftDatabase(name: 'assisbant_db');
}
