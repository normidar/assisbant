import 'package:drift/drift.dart';
import 'package:assibant/src/data/database/app_database.dart';
import 'package:assibant/src/data/database/prompt_status.dart';
import 'package:assibant/src/data/models/branch_summary.dart';
import 'package:uuid/uuid.dart';

class PromptRepository {
  const PromptRepository(this._db);

  final AppDatabase _db;

  static const _uuid = Uuid();

  // ── Queries ──────────────────────────────────────────────────────────────

  Future<List<PromptEntry>> getAll() =>
      (_db.select(_db.prompts)..orderBy([(t) => OrderingTerm.asc(t.priority)]))
          .get();

  Future<List<PromptEntry>> getByBranch(String branch) =>
      (_db.select(_db.prompts)
            ..where((t) => t.branch.equals(branch))
            ..orderBy([(t) => OrderingTerm.asc(t.priority)]))
          .get();

  /// Returns pending, non-skipped prompts ordered by priority — ready to execute.
  Future<List<PromptEntry>> getExecutable() =>
      (_db.select(_db.prompts)
            ..where(
              (t) =>
                  t.status.equals(PromptStatus.pending.name) &
                  t.isSkipped.equals(false),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.priority)]))
          .get();

  Future<List<String>> getProjectPaths() async {
    final rows = await (_db.selectOnly(_db.prompts)
          ..addColumns([_db.prompts.projectPath])
          ..where(_db.prompts.projectPath.isNotValue(''))
          ..groupBy([_db.prompts.projectPath])
          ..orderBy([OrderingTerm.asc(_db.prompts.projectPath)]))
        .get();
    return rows.map((r) => r.read(_db.prompts.projectPath)!).toList();
  }

  Future<List<String>> getBranchNames() async {
    final rows = await (_db.selectOnly(_db.prompts)
          ..addColumns([_db.prompts.branch])
          ..groupBy([_db.prompts.branch])
          ..orderBy([OrderingTerm.asc(_db.prompts.branch)]))
        .get();
    return rows.map((r) => r.read(_db.prompts.branch)!).toList();
  }

  Future<List<BranchSummary>> getBranchSummaries() async {
    final all = await getAll();
    final grouped = <String, List<PromptEntry>>{};
    for (final p in all) {
      grouped.putIfAbsent(p.branch, () => []).add(p);
    }
    return grouped.entries
        .map((e) => BranchSummary(name: e.key, prompts: e.value))
        .toList();
  }

  /// Returns the next available priority value (max + 1, or 1 if empty).
  Future<int> getNextPriority() async {
    final expr = _db.prompts.priority.max();
    final row = await (_db.selectOnly(_db.prompts)..addColumns([expr])).getSingle();
    final max = row.read(expr);
    return (max ?? 0) + 1;
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  Future<PromptEntry> insert({
    required String content,
    required String branch,
    required String projectPath,
    int? priority,
    String sessionId = '',
    String claudeModel = '',
    String imagePaths = '',
    bool commitAfterRun = false,
  }) async {
    final now = DateTime.now();
    final resolvedPriority = priority ?? await getNextPriority();
    final entry = PromptsCompanion.insert(
      id: _uuid.v4(),
      content: content,
      branch: branch,
      projectPath: Value(projectPath),
      priority: Value(resolvedPriority),
      sessionId: Value(sessionId),
      claudeModel: Value(claudeModel),
      imagePaths: Value(imagePaths),
      commitAfterRun: Value(commitAfterRun),
      createdAt: now,
      updatedAt: now,
    );
    await _db.into(_db.prompts).insert(entry);
    return (
      _db.select(_db.prompts)
        ..where((t) => t.id.equals(entry.id.value))
    ).getSingle();
  }

  Future<void> update(PromptEntry prompt) => _db
      .update(_db.prompts)
      .replace(prompt.copyWith(updatedAt: DateTime.now()));

  Future<void> updateContent(String id, String content) =>
      (_db.update(_db.prompts)..where((t) => t.id.equals(id))).write(
        PromptsCompanion(
          content: Value(content),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> updateStatus(String id, PromptStatus status) =>
      (_db.update(_db.prompts)..where((t) => t.id.equals(id))).write(
        PromptsCompanion(
          status: Value(status),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> updatePriority(String id, int priority) =>
      (_db.update(_db.prompts)..where((t) => t.id.equals(id))).write(
        PromptsCompanion(
          priority: Value(priority),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> updateBranch(String id, String branch) =>
      (_db.update(_db.prompts)..where((t) => t.id.equals(id))).write(
        PromptsCompanion(
          branch: Value(branch),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> updateProjectPath(String id, String projectPath) =>
      (_db.update(_db.prompts)..where((t) => t.id.equals(id))).write(
        PromptsCompanion(
          projectPath: Value(projectPath),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> setSkipped(String id, {required bool isSkipped}) =>
      (_db.update(_db.prompts)..where((t) => t.id.equals(id))).write(
        PromptsCompanion(
          isSkipped: Value(isSkipped),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> updateOutput(String id, String output) =>
      (_db.update(_db.prompts)..where((t) => t.id.equals(id))).write(
        PromptsCompanion(
          output: Value(output),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> updateStartedAt(String id) =>
      (_db.update(_db.prompts)..where((t) => t.id.equals(id))).write(
        PromptsCompanion(
          startedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> updateSessionId(String id, String sessionId) =>
      (_db.update(_db.prompts)..where((t) => t.id.equals(id))).write(
        PromptsCompanion(
          sessionId: Value(sessionId),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> updateClaudeSessionId(String id, String claudeSessionId) =>
      (_db.update(_db.prompts)..where((t) => t.id.equals(id))).write(
        PromptsCompanion(
          claudeSessionId: Value(claudeSessionId),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Returns distinct non-empty sessionId values used for the given
  /// projectPath and branch, ordered by most recent updatedAt.
  Future<List<String>> getSessionIds(String projectPath, String branch) async {
    final rows = await (_db.select(_db.prompts)
          ..where(
            (t) =>
                t.projectPath.equals(projectPath) &
                t.branch.equals(branch) &
                t.sessionId.isNotValue(''),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
    final seen = <String>{};
    return rows.map((r) => r.sessionId).where(seen.add).toList();
  }

  /// Returns the claude session ID from the most recently completed prompt
  /// sharing the same user-defined [sessionId], or null if none exists yet.
  Future<String?> getLatestClaudeSessionId(String sessionId) async {
    final rows = await (_db.select(_db.prompts)
          ..where(
            (t) =>
                t.sessionId.equals(sessionId) &
                t.claudeSessionId.isNotValue('') &
                t.status.equals(PromptStatus.done.name),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
          ..limit(1))
        .get();
    return rows.isEmpty ? null : rows.first.claudeSessionId;
  }

  Future<List<PromptEntry>> getByProjectPaths(List<String> paths) =>
      (_db.select(_db.prompts)
            ..where((t) => t.projectPath.isIn(paths))
            ..orderBy([(t) => OrderingTerm.asc(t.priority)]))
          .get();

  Future<List<PromptEntry>> getUnassigned() =>
      (_db.select(_db.prompts)
            ..where((t) => t.projectPath.equals(''))
            ..orderBy([(t) => OrderingTerm.asc(t.priority)]))
          .get();

  Future<int> importBatch(List<PromptsCompanion> entries) async {
    await _db.batch((batch) {
      batch.insertAll(_db.prompts, entries);
    });
    return entries.length;
  }

  Future<void> resetStatus(String id) =>
      updateStatus(id, PromptStatus.pending);

  Future<int> delete(String id) =>
      (_db.delete(_db.prompts)..where((t) => t.id.equals(id))).go();

  // ── Streams ───────────────────────────────────────────────────────────────

  Stream<List<PromptEntry>> watchAll() =>
      (_db.select(_db.prompts)
            ..orderBy([(t) => OrderingTerm.asc(t.priority)]))
          .watch();

  Stream<List<PromptEntry>> watchByBranch(String branch) =>
      (_db.select(_db.prompts)
            ..where((t) => t.branch.equals(branch))
            ..orderBy([(t) => OrderingTerm.asc(t.priority)]))
          .watch();
}
