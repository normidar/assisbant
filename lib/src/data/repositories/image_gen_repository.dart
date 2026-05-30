import 'package:assibant/src/data/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class ImageGenRepository {
  const ImageGenRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  Future<ImageGenRecord> insert({
    required String prompt,
    required String negativePrompt,
    required String model,
    required int width,
    required int height,
    required int steps, required int generationTimeMs, required DateTime startedAt, required DateTime finishedAt, required String status, int? seed,
    String? imagePath,
    String? errorMessage,
    int iteration = 0,
  }) async {
    final id = _uuid.v4();
    final entry = ImageGenRecordsCompanion.insert(
      id: id,
      prompt: prompt,
      negativePrompt: Value(negativePrompt),
      model: Value(model),
      width: Value(width),
      height: Value(height),
      seed: Value(seed),
      steps: Value(steps),
      generationTimeMs: Value(generationTimeMs),
      startedAt: startedAt,
      finishedAt: finishedAt,
      imagePath: Value(imagePath),
      status: Value(status),
      errorMessage: Value(errorMessage),
      iteration: Value(iteration),
    );
    await _db.into(_db.imageGenRecords).insert(entry);
    return (_db.select(_db.imageGenRecords)
          ..where((t) => t.id.equals(id)))
        .getSingle();
  }

  Future<List<ImageGenRecord>> getAll() =>
      (_db.select(_db.imageGenRecords)
            ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
          .get();

  Future<void> updateImagePath(String id, String imagePath) =>
      (_db.update(_db.imageGenRecords)..where((t) => t.id.equals(id))).write(
        ImageGenRecordsCompanion(imagePath: Value(imagePath)),
      );
}
