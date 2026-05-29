import 'package:assibant/src/data/database/app_database.dart';
import 'package:assibant/src/data/repositories/image_gen_repository.dart';
import 'package:assibant/src/data/repositories/prompt_repository.dart';
import 'package:assibant/src/data/services/execution_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'database_providers.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}

@Riverpod(keepAlive: true)
PromptRepository promptRepository(Ref ref) =>
    PromptRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
ImageGenRepository imageGenRepository(Ref ref) =>
    ImageGenRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
ExecutionService executionService(Ref ref) => const ExecutionService();
